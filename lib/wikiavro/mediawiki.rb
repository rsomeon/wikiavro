require 'wikiavro/xml'

# RW declares schema 0.6 but has redirects as in 0.7
#
# RW has <sha1> tags right after <redirect> - they are indented to a
# different level too. The <sha1>s are missing within <revision>s
# where they should be.
#
# Schema claims discussionthreadinginfo, but actual tag is
# DiscussionThreading. Schema does not describe ThreadSummaryPage or
# ThreadSignature. Schema does not describe which LQT tags are
# omissible. Schema says thread info should always come after
# revisions, but it does not.

module WikiAvro::MediaWiki
  class NamespacePrinter
    def write(key, casetype, name)
      puts "namespace #{key}: \"#{name}\" #{casetype}"
    end
  end

  class PagePrinter
    def write(ns, id, title, redirect, sha1)
      puts "page \"#{title}\": #{id} #{ns} #{redirect} #{sha1}"
    end
  end

  class RevisionPrinter
    def write(id, page_id, n, timestamp, contributor, minor,
              comment, text_deleted, bytes, textid, text)
      puts "rev #{page_id} #{n}: #{timestamp} " +
           "#{bytes} #{contributor[:username]}"
    end
  end

  class LqtPrinter
    def write(threadSubject, threadParent, threadAncestor,
              threadPage, threadID, threadSummaryPage,
              threadAuthor, threadEditStatus, threadType,
              threadSignature)
      puts "thread #{threadSubject} #{threadParent} #{threadAncestor} " +
           "#{threadAuthor} #{threadEditStatus} #{threadType}"
    end
  end

  class NullWriter
    def method_missing(target, *args, &block)
      # All methods return nil
    end

    def initialize
    end
  end

  class WikiWriter
    def initialize(writers)
      null_writer = NullWriter.new
      @namespace = (writers[:namespace] or NamespacePrinter.new)
      @logger = (writers[:logger] or NoProgress.new)
      @page = (writers[:page] or NullWriter.new)
      @revision = (writers[:revision] or NullWriter.new)
      @lqt = (writers[:lqt] or NullWriter.new)
    end

    def namespace(key, casetype, name)
      @namespace.write(key, casetype, name)
    end

    def page(ns, id, title, redirect, sha1)
      @logger.report_pages(1)
      @page.write(ns, id, title, redirect, sha1)
    end

    def revision(id, page_id, n, timestamp, contributor, minor,
                 comment, text_deleted, bytes, textid, text)
      @logger.report_revisions(1)
      @revision.write(id, page_id, n, timestamp, contributor, minor,
                      comment, text_deleted, bytes, textid, text)
    end

    def lqt(threadSubject, threadParent, threadAncestor,
            threadPage, threadID, threadSummaryPage,
            threadAuthor, threadEditStatus, threadType,
            threadSignature)
      @lqt.write(threadSubject, threadParent, threadAncestor,
                 threadPage, threadID, threadSummaryPage,
                 threadAuthor, threadEditStatus, threadType,
                 threadSignature)
    end

    def done
      @logger.report_done
    end

    def skipped(name)
#      puts "wikiwriter: skipped element #{name}"
#      raise 'what?'
      @logger.report_skipped_element(name)
    end
  end

  class NoProgress
    def report_pages(n)
    end

    def report_revisions(n)
    end

    def report_done
    end

    def report_skipped_element(name)
    end
  end

  class FinalProgress
    def f(n)
      parts = []
      while n >= 1
        parts.unshift(n % 1000)
        n /= 1000
      end
      head = parts.shift
      if parts.empty?
        if head
          head.to_s
        else
          n
        end
      else
        [head, parts.map {|p| sprintf('%03d', p)}.join(',')].join(',')
      end
    end

    def total_skipped
      @skipped_counts.values.reduce(0, :+)
    end

    def report_pages(n)
      @pages += n
    end

    def report_revisions(n)
      @revisions += n
    end

    def report_skipped_element(name)
      @skipped_counts[name] += 1
    end

    def show_skipped
      @skipped_counts.each do |name, count|
        puts "#{name}: #{count}"
      end
    end

    def report_done
      duration = Time.now - @start_time
      avg_rate = @revisions / duration
      h = (duration / 60 / 60).floor
      m = (duration % (60 * 60) / 60).floor
      s = (duration % 60).floor
      # FIXME: Print to STDERR or some log
      skipped = total_skipped
      if skipped > 0
        puts "Couldn't process #{skipped} elements! Detailed breakdown:"
        show_skipped
      end
      puts "Done! Took #{h}h#{m}m#{s}s. Averaged #{f avg_rate.round(0)} rps."
    end

    def initialize
      @start_time = Time.now
      @pages = 0
      @revisions = 0
      @skipped_counts = Hash.new 0
    end
  end

  class RevisionProgress < FinalProgress
    def announce_progress
      now = Time.now
      rps = (@revisions - @previous_revisions) / (now - @previous_time)
      puts "Page #{f @pages}, rev #{f @revisions} (#{f rps.round(0)} rps)"
      skipped = total_skipped
      puts "#{f skipped} unprocessable elements so far."
      show_skipped
      @previous_time = now
      @previous_revisions = @revisions
    end

    def report_revisions(n)
      super(n)

      if @revisions - @previous_revisions >= @interval
        announce_progress
      end
    end

    def report_done
      announce_progress
      super
    end

    def initialize(interval)
      super()
      @interval = interval
      @previous_time = @start_time
      @previous_revisions = 0
    end
  end

  class Namespace < WikiAvro::XML::Leaf
    def name
      'namespace'
    end

    def reset
      # everything is overwritten each cycle anyway
    end

    def parse_attributes(w, p, r)
      @key = r['key']
      @case = r['case']
    end

    def parse_content(w, p, r)
      name = r.read_string
      WikiAvro::XML.skip_tag(w, r, false)
      w.namespace(@key, @case, name)
    end
  end

  class NamespaceStream < WikiAvro::XML::Stream
    def initialize
      super([Namespace.new])
    end
  end

  class Sitename < WikiAvro::XML::Inserter
    def initialize
      super('sitename')
    end
  end

  class Base < WikiAvro::XML::Inserter
    def initialize
      super('base')
    end
  end

  class Generator < WikiAvro::XML::Inserter
    def initialize
      super('generator')
    end
  end

  class Case < WikiAvro::XML::Inserter
    def initialize
      super('case')
    end
  end

  class Namespaces < WikiAvro::XML::Element
    def name
      'namespaces'
    end

    def initialize
      super([NamespaceStream.new])
    end
  end

  class SiteInfo < WikiAvro::XML::Element
    attr_accessor :sitename
    attr_accessor :base
    attr_accessor :generator
    attr_accessor :case

    def name
      'siteinfo'
    end

    def reset
      @sitename = nil
      @base = nil
      @generator = nil
      @case = nil
    end

    def initialize
      super([Sitename.new, Base.new, Generator.new,
             Case.new, Namespaces.new])
    end
  end

  class Title < WikiAvro::XML::Inserter
    def initialize
      super('title')
    end
  end

  class Ns < WikiAvro::XML::Inserter
    def initialize
      super('ns')
    end
  end

  class Id < WikiAvro::XML::Inserter
    def initialize
      super('id')
    end
  end

  class Redirect < WikiAvro::XML::Leaf
    def name
      'redirect'
    end

    def parse_attributes(w, p, r)
#      puts "redirect: #{r['title']}"
      p.redirect = r['title']
    end
  end

  class Sha1 < WikiAvro::XML::Inserter
    def initialize
      super('sha1')
    end
  end

  class PageFlags < WikiAvro::XML::Group
    def initialize
      super [{:element => Redirect.new, :min => 0, :max => 1},
             {:element => Sha1.new, :min => 0, :max => 1}]
    end
  end

  class Timestamp < WikiAvro::XML::Inserter
    def initialize
      super('timestamp')
    end
  end

  class Username < WikiAvro::XML::Inserter
    def initialize
      super('username')
    end
  end

  class Ip < WikiAvro::XML::Inserter
    def initialize
      super('ip')
    end
  end

  class ContributorGroup < WikiAvro::XML::Group
    def optional?
      true
    end

    def initialize
      super [{:element => Username.new, :min => 0, :max => 1},
             {:element => Id.new, :min => 0, :max => 1},
             {:element => Ip.new, :min => 0, :max => 1}]
    end
  end

  class Contributor < WikiAvro::XML::Element
    def name
      'contributor'
    end

    attr_accessor :id
    attr_accessor :username
    attr_accessor :ip

    def reset
      @id = nil
      @username = nil
      @ip = nil
      @deleted = nil
    end

    def parse_attributes(w, p, r)
      @deleted = r['deleted']
    end

    def handle_content(w, p, r)
      p.contributor = {:deleted => @deleted, :id => id,
                       :username => username, :ip => ip}
    end

    def initialize
      super([ContributorGroup.new])
    end
  end

  class Minor < WikiAvro::XML::Inserter
    def initialize
      super('minor')
    end
  end

  class Comment < WikiAvro::XML::Leaf
    def name
      'comment'
    end

    def parse_attributes(w, p, r)
      deleted = r['deleted']
      comment = r.read_string
      p.comment = {:deleted => deleted,
                   :comment => comment}
    end
  end

  class RevisionFlags < WikiAvro::XML::Group
    def initialize
      super [{:element => Minor.new, :min => 0, :max => 1},
             {:element => Comment.new, :min => 0, :max => 1}]
    end
  end

  class Text < WikiAvro::XML::Inserter
    def parse_attributes(w, p, r)
      p.text_deleted = r['deleted']
      p.textid = r['id']
      p.bytes = r['bytes']
    end

    def initialize
      super('text')
    end
  end

  class Revision < WikiAvro::XML::Element
    attr_accessor :id
    attr_accessor :timestamp
    attr_accessor :contributor
    attr_accessor :minor
    attr_accessor :comment
    attr_accessor :text_deleted
    attr_accessor :bytes
    attr_accessor :textid
    attr_accessor :text

    def name
      'revision'
    end

    def reset
      id = nil
      timestamp = nil
      contributor = nil
      minor = nil
      comment = nil
      text_deleted = nil
      bytes = nil
      textid = nil
      text = nil
    end

    def handle_content(w, p, r)
      p.revision_count += 1
      n = p.revision_count
      w.revision(id, p.id, n, timestamp, contributor, minor,
                 comment, text_deleted, bytes, textid, text)
    end

    def initialize
      super([Id.new, Timestamp.new, Contributor.new,
             RevisionFlags.new, Text.new])
    end
  end

  class RevStream < WikiAvro::XML::Stream
    def initialize
      super([Revision.new])
    end
  end

  class ThreadSubject < WikiAvro::XML::Inserter
    def initialize
      super('ThreadSubject', 'threadSubject')
    end
  end

  class ThreadParent < WikiAvro::XML::Inserter
    def initialize
      super('ThreadParent', 'threadParent')
    end
  end

  class ThreadAncestor < WikiAvro::XML::Inserter
    def initialize
      super('ThreadAncestor', 'threadAncestor')
    end
  end

  class ThreadParentGroup < WikiAvro::XML::Group
    def optional?
      true
    end

    def initialize
      super [{:element => ThreadParent.new, :min => 0, :max => 1},
             {:element => ThreadAncestor.new, :min => 0, :max => 1}]
    end
  end

  class ThreadPage < WikiAvro::XML::Inserter
    def initialize
      super('ThreadPage', 'threadPage')
    end
  end

  class ThreadID < WikiAvro::XML::Inserter
    def initialize
      super('ThreadID', 'threadID')
    end
  end

  class ThreadSummaryPage < WikiAvro::XML::Inserter
    def initialize
      super('ThreadSummaryPage', 'threadSummaryPage')
    end
  end

  class ThreadSummaryPageGroup < WikiAvro::XML::Group
    def optional?
      true
    end

    def initialize
      super [{:element => ThreadSummaryPage.new, :min => 0, :max => 1}]
    end
  end

  class ThreadAuthor < WikiAvro::XML::Inserter
    def initialize
      super('ThreadAuthor', 'threadAuthor')
    end
  end

  class ThreadEditStatus < WikiAvro::XML::Inserter
    def initialize
      super('ThreadEditStatus', 'threadEditStatus')
    end
  end

  class ThreadType < WikiAvro::XML::Inserter
    def initialize
      super('ThreadType', 'threadType')
    end
  end

  class ThreadSignature < WikiAvro::XML::Inserter
    def initialize
      super('ThreadSignature', 'threadSignature')
    end
  end

  class DiscussionThreading < WikiAvro::XML::Element
    attr_accessor :threadSubject, :threadParent, :threadAncestor,
                  :threadPage, :threadID, :threadSummaryPage,
                  :threadAuthor, :threadEditStatus, :threadType,
                  :threadSignature
    def name
      'DiscussionThreading'
    end

    def reset
      threadSubject = nil
      threadParent = nil
      threadAncestor = nil
      threadPage = nil
      threadID = nil
      threadSummaryPage = nil
      threadAuthor = nil
      threadEditStatus = nil
      threadType = nil
      threadSignature = nil
    end

    def handle_content(w, p, r)
      w.lqt(threadSubject, threadParent, threadAncestor,
            threadPage, threadID, threadSummaryPage,
            threadAuthor, threadEditStatus, threadType,
            threadSignature)
    end

    def initialize
      super([ThreadSubject.new, ThreadParentGroup.new, ThreadPage.new,
             ThreadID.new, ThreadSummaryPageGroup.new, ThreadAuthor.new,
             ThreadEditStatus.new, ThreadType.new, ThreadSignature.new])
    end
  end

  class DiscussionThreadingGroup < WikiAvro::XML::Group
    def optional?
      true
    end

    def initialize
      super [{:element => DiscussionThreading.new, :min => 0, :max => 1}]
    end
  end

  class Page < WikiAvro::XML::Element
    attr_accessor :title
    attr_accessor :ns
    attr_accessor :id
    attr_accessor :redirect
    attr_accessor :sha1
    attr_accessor :revision_count

    def name
      'page'
    end

    def reset
      title = nil
      ns = nil
      id = nil
      redirect = nil
      sha1 = nil
      revision_count = nil
      @revision_count = 0
    end

    def handle_content(w, p, r)
      w.page(ns, id, title, redirect, sha1)
    end

    def initialize
      super([Title.new, Ns.new, Id.new, PageFlags.new,
             RevStream.new, DiscussionThreadingGroup.new,
             RevStream.new])
    end
  end

  class PageStream < WikiAvro::XML::Stream
    def initialize
      super([Page.new])
    end
  end

  class WikiDump < WikiAvro::XML::Element
    attr_reader :version

    def name
      'mediawiki'
    end

    protected

    def parse_attributes(w, p, r)
      @version = r['version']
      warn 'dump version != 0.6' if @version != '0.6'
    end

    def handle_content(w, p, r)
      w.done
    end

    def initialize
      super([SiteInfo.new, PageStream.new])
    end
  end
end

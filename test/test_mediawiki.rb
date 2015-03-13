# coding: utf-8
require 'minitest'
require 'minitest/autorun'
require 'wikiavro'
require 'wikiavro/nokogiri'

valid_single_page_sample = IO.read('test/valid-single-page.xml')
valid_extra_element_sample = IO.read('test/valid-extra-element.xml')

def parse_string(str)
    dump = WikiAvro::MediaWiki::WikiDump.new
    ns = WikiAvro::MediaWiki::NullWriter.new
    page = WikiAvro::MediaWiki::NullWriter.new
    rev = WikiAvro::MediaWiki::NullWriter.new
    lqt = WikiAvro::MediaWiki::NullWriter.new
    logger = WikiAvro::MediaWiki::AccumulateProgress.new
    reader = WikiAvro::XML::Nokogiri::Reader.io(StringIO.new(str))
    writer = writer = WikiAvro::MediaWiki::WikiWriter.new :logger => logger,
                                                          :namespace => ns,
                                                          :page => page,
                                                          :revision => rev,
                                                          :lqt => lqt
    dump.parse(writer, nil, reader)
    return logger
end

describe WikiAvro::MediaWiki::WikiDump do
  describe '#parse' do
    describe 'when passed a valid dump consisting of a single page' do
      before do
        @logger = parse_string(valid_single_page_sample)
      end

      it 'does not not skip elements' do
        assert_equal 0, @logger.skipped
      end

      it 'parses one page' do
        assert_equal 1, @logger.pages
      end

      it 'reports the number of revisions' do
        assert_equal 40, @logger.revisions
      end
    end

    describe 'when passed a valid dump with an extraneous element' do
      before do
        @logger = parse_string(valid_extra_element_sample)
      end

      # Note that it might also throw an exception. I handpicked a
      # benign location for the extra element.
      it 'skips one element' do
        assert_equal 1, @logger.skipped
      end

      it 'parses one page' do
        assert_equal 1, @logger.pages
      end

      it 'reports the number of revisions' do
        assert_equal 40, @logger.revisions
      end
    end
  end
end

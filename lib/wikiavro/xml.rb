# Parser functions will assume to possibly start on their opening tag,
# and stop parsing right after their end tag. There're probably loads
# of bugs waiting for when you nest tags of the same name.

module WikiAvro::XML
  def self.to_tag(reader)
#    puts 'to_tag: moving to tag'
    loop do
      case reader.node_type
      when XML::Reader::TYPE_ELEMENT
#        puts "to_tag: got tag #{reader.name}"
        return true
      when XML::Reader::TYPE_END_ELEMENT
#        puts "to_tag: got end tag #{reader.name}"
        return false
      end

      break if !reader.read
    end

    # XML::Reader will probably raise its own exception before we ever
    # could get here
    raise EOFError.new('no opening tag')
  end

  # Do not call this while you are on the opening tag
  def self.exit_tag(writer, reader, name)
    nest = 1

#    puts "exit_tag: exiting #{name}"

    loop do
      case reader.node_type
      when XML::Reader::TYPE_ELEMENT
#        puts "exit_tag: entered #{reader.name}"
        writer.skipped(reader.name)
        nest += 1 if reader.name == name
      when XML::Reader::TYPE_END_ELEMENT
#        puts "exit_tag: exited #{reader.name}"
        nest -= 1 if reader.name == name
      end
      reader.read
      if nest == 0
#        puts "exit_tag: successful exit, now at #{reader.name}"
        break
      end
    end
  end

  # Call this to skip when reader is on the opening tag
  def self.skip_tag(writer, reader, skipping)
    nest = 1
    name = reader.name

#    puts "skip_tag: skipping #{name}"

    if reader.empty_element?
#      puts "skip_tag: element was empty; skipped"
      writer.skipped(name) if skipping
      reader.read
      return
    end

    while reader.read
      case reader.node_type
      when XML::Reader::TYPE_ELEMENT
#        puts "skip_tag: entered #{reader.name}"
        writer.skipped(reader.name) if skipping
        nest += 1 if reader.name == name
      when XML::Reader::TYPE_END_ELEMENT
#        puts "skip_tag: exited #{reader.name}"
        nest -= 1 if reader.name == name
      end
      if nest == 0
        reader.read
        break
      end
    end
  end

  class MissingElement < Exception
  end

  def self.to_element(writer, reader, name)
    while WikiAvro::XML::to_tag(reader)
#      puts "to_element: saw #{reader.name}"
      if reader.name == name
        return
      else
#        puts "to_element: skipping #{reader.name}"
        WikiAvro::XML.skip_tag(writer, reader, true)
#        puts "to_element: skipped"
      end

      break if !reader.read
    end

    raise MissingElement.new(name)
  end

  class Element
    attr_reader :attr

    def name
      raise NotImplementedError.new('name')
    end

    def optional?
      false
    end

    def parse(output, parent, reader)
      if parent.nil? && reader.name != self.name
        raise RuntimeError.new('reader.name != self.name')
      else
        WikiAvro::XML::to_element(output, reader, self.name)
      end

      reset
      @attr = parse_attributes(output, parent, reader)
      parse_content(output, parent, reader)
      handle_content(output, parent, reader)
    end

    protected

    # Instances will be reused. Subclasses that keep state which needs
    # to be discarded after each parse should implement this.
    def reset
    end

    def parse_attributes(w, p, r)
      # no attributes parsed
    end

    # parse_content should move the reader away from the children's
    # parent's opening tag. It should leave reader positioned after
    # the closing tag.
    def parse_content(w, p, r)
      if r.empty_element?
        @children.each do |c|
          raise MissingElement.new(c.name) if !c.optional?
        end
        r.read
        return
      end

      # Move away from our opening tag
      r.read
      @children.each do |c|
#        puts "element: parsing #{c.class}"
        c.parse(w, self, r)
#        puts "parsed #{c.class}"
      end

      if r.empty_element? && r.name == self.name
#        puts "got empty: #{r.name}"
        r.read
#        puts "now got this: #{r.name}"
      else
#        puts "mopping up #{self.name}"
        WikiAvro::XML.exit_tag(w, r, self.name)
      end
    end

    def handle_content(w, p, r)
      # nothing done
    end

    private

    def initialize(children)
      @children = children
    end
  end

  class Leaf < Element
    def initialize
      super([])
    end
  end

  class Inserter < Leaf
    attr_reader :name

    def parse_content(w, p, r)
      p.send(@writer, r.read_string)
#      puts "inserter: exiting #{@name}"
      WikiAvro::XML.skip_tag(w, r, false)
#      puts "exited"
    end

    def initialize(name, target=name)
      super()
      @name = name
      @writer = (target + '=').to_sym
    end
  end

  class Stream
    def optional?
      true
    end

    def parse(output, parent, reader)
#      puts "stream: parsing #{self.class}"

      while WikiAvro::XML::to_tag(reader)
        e = @elements[reader.name]

        if e.nil?
#          puts "stream: rejected #{reader.name}"
          return
        else
#          puts "stream: accepted #{reader.name}"
          e.parse(output, parent, reader)
          reader.read
        end
      end

#      puts "stream: ran to parent end"
    end

    private

    def initialize(elements)
      @elements = {}
      elements.each { |e| @elements[e.name] = e }
    end
  end

  class TooManyElements < Exception
  end

  class TooFewElements < Exception
  end

  class Group
    # remember to override this if untrue, especially if it might be
    # within an empty element
    def optional?
      false
    end

    def parse(output, parent, reader)
      @n.keys.each {|k| @n[k] = 0}

      while WikiAvro::XML::to_tag(reader)
        e = @elements[reader.name]

        if e.nil?
          @elements.each do |k, v|
            raise TooFewElements.new(k) if @n[k] < v[:min]
            # this ought to be a redundant check
            raise TooManyElements.new(k) if @n[k] > v[:max]
          end
#          puts "group: rejected #{reader.name}"
          return
        else
#          puts "group: accepted #{reader.name}"
          name = reader.name
          @n[name] += 1
          raise TooManyElements.new(name) if @n[name] > e[:max]
          e[:element].parse(output, parent, reader)
          reader.read
        end
      end

#      puts 'group: ran to parent end'
    end

    def initialize(elements)
      @elements = {}
      @n = Hash.new 0
      elements.each do |e|
        name = e[:element].name
        @elements[name] = e
        @n[name] = 0
      end
    end
  end
end

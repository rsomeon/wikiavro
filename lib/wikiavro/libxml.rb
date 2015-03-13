require 'xml'

module WikiAvro::XML::LibXML
  class Reader
    def self.io(stream)
      reader = XML::Reader.io(stream)
      reader.read
      self.new(reader)
    end

    def initialize(reader)
      @reader = reader
    end

    def read
      @reader.read
    end

    def element?
      @reader.node_type == XML::Reader::TYPE_ELEMENT
    end

    def end_element?
      @reader.node_type == XML::Reader::TYPE_END_ELEMENT
    end

    def name
      @reader.name
    end

    def empty_element?
      @reader.empty_element?
    end

    def read_string
      @reader.read_string
    end

    def [](attr)
      @reader[attr]
    end
  end
end

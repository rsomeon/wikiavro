require 'nokogiri'

module WikiAvro::XML::Nokogiri
  class Reader
    def self.io(stream)
      reader = ::Nokogiri::XML::Reader.from_io(stream)
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
      @reader.node_type == ::Nokogiri::XML::Reader::TYPE_ELEMENT
    end

    def end_element?
      @reader.node_type == ::Nokogiri::XML::Reader::TYPE_END_ELEMENT
    end

    def name
      @reader.name
    end

    # Apparently <this></this> counts as self-closing to nokogiri.
    def empty_element?
      return false if @reader.name == 'mediawiki'
      @reader.self_closing?
    end

    def read_string
      # This could be another gotcha.
      @reader.inner_xml unless empty_element?
    end

    def [](attr)
      if @reader.attributes?
        @reader.attribute(attr)
      end
    end
  end
end

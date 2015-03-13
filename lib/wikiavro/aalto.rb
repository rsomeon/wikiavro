require 'java'
require 'jbundler'

java_import com.fasterxml.aalto.stax.InputFactoryImpl

module WikiAvro::XML::Aalto
  class Reader
    def self.io(stream)
      factory = InputFactoryImpl.new
      factory.configureForSpeed
      reader = factory.createXMLStreamReader(stream.to_io.to_inputstream)
      reader.next
      self.new(reader)
    end

    def initialize(reader)
      @reader = reader
    end

    def read
      return false unless @reader.hasNext
      @reader.next
#      puts "aalto read_string: advanced to #{name} #{element?}"
      @reader.hasNext
    end

    def element?
      @reader.isStartElement
    end

    def end_element?
      @reader.isEndElement
    end

    def name
      return unless @reader.hasName
      @reader.getName.getLocalPart
    end

    # StAX always emits end elements for empty elements
    def empty_element?
      false
    end

    def read_string
      @reader.getElementText
    end

    def [](attr)
      @reader.getAttributeValue(nil, attr)
    end
  end
end

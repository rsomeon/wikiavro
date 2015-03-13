require File.join(File.dirname(__FILE__), 'lib/wikiavro/version')

begin
  require 'jbundler'
rescue LoadError
  # We don't have jbundler yet when bundle install (which will try to
  # load this file) is first run
else
  FileUtils::cp(JBUNDLER_CLASSPATH, 'lib/wikiavro/jars/')
end

Gem::Specification.new do |s|
  s.name = 'wikiavro'
  s.version = WikiAvro::VERSION
  s.summary = 'Convert MediaWiki XML dumps to Avro'
  s.homepage = 'https://github.com/rsomeon/wikiavro'
  s.authors = ['Someon']
  s.email = 'someon@openmailbox.org'
  s.files = Dir['lib/**/*.rb', 'lib/**/*.jar']
  s.test_files = Dir['test/**/*.rb']
  s.executables << 'wikiavro'
  s.add_runtime_dependency 'nokogiri', '~> 1.6'
  s.add_runtime_dependency 'avro', '~> 1.7'
  s.license = 'GPL-3.0+'
end

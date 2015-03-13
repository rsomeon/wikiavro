require File.join(File.dirname(__FILE__), 'lib/wikiavro/version')

begin
  require 'jbundler'
  FileUtils::cp(JBUNDLER_CLASSPATH, 'lib/wikiavro/jars/')
rescue LoadError, NameError
  # We don't have jbundler yet when bundle install (which will try to
  # load this file) is first run
end

Gem::Specification.new do |s|
  s.name = 'wikiavro'
  s.version = WikiAvro::VERSION
  s.summary = 'Convert MediaWiki XML dumps to Avro'
  s.homepage = 'https://github.com/rsomeon/wikiavro'
  s.authors = ['Someon']
  s.email = 'someon@openmailbox.org'
  s.files = Dir['lib/**/*.rb', 'lib/**/*.jar']
  s.test_files = Dir['test/**/*.rb', 'test/**/*.xml']
  s.executables << 'wikiavro'
  s.add_runtime_dependency 'nokogiri', '~> 1.6'
  s.add_runtime_dependency 'avro', '~> 1.7'
  s.add_development_dependency 'jbundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
  s.license = 'GPL-3.0+'
end

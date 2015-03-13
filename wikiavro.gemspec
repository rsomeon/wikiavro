require File.expand_path('../lib/wikiavro/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'wikiavro'
  s.version = WikiAvro::VERSION
  s.summary = 'Convert MediaWiki XML dumps to Avro'
  s.authors = ['Someon']
  s.email = 'someon@openmailbox.org'
  s.files = Dir['lib/**/*.rb']
  s.executables << 'wikiavro'
  s.add_runtime_dependency 'libxml-ruby', '~> 2.7'
  s.add_runtime_dependency 'avro', '~> 1.7'
  s.license = 'GPL-3.0+'
end

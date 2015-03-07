Gem::Specification.new do |s|
  s.name = 'wikiavro'
  s.version = '0.0.2'
  s.summary = 'Convert MediaWiki XML dumps to Avro'
  s.authors = ['Someon']
  s.email = 'someon@openmailbox.org'
  s.files = ['lib/wikiavro.rb', 'lib/wikiavro/xml.rb',
             'lib/wikiavro/mediawiki.rb', 'lib/wikiavro/avro.rb']
  s.executables << 'wikiavro'
  s.add_runtime_dependency 'libxml-ruby', '~> 2.7'
  s.add_runtime_dependency 'avro', '~> 1.7'
  s.license = 'GPL-3.0+'
end

require 'minitest/autorun'

describe "require 'wikiavro'" do
  it "succeeds on all platforms" do
    require 'wikiavro'
  end
end

describe "require 'wikiavro/nokogiri'" do
  before do
    require 'wikiavro'
  end

  it "succeeds on all platforms" do
    require 'wikiavro/nokogiri'
  end
end

Gem::Specification.new do |s|
  s.name        = 'grizzly_ber'
  s.version     = '1.1.1'
  s.date        = '2015-07-29'
  s.summary     = "Fiercest TLV-BER parser"
  s.description = "CODEC for EMV TLV-BER encoded strings."
  s.authors     = ["Ryan Balsdon"]
  s.email       = 'ryan.balsdon@shopify.com'
  s.homepage    = 'https://github.com/Shopify/grizzly_ber'
  s.license     = 'MIT'
  s.files       = ["lib/grizzly_ber.rb", "lib/grizzly_tag.rb"]
  
  s.metadata["allowed_push_host"] = "https://rubygems.org"

  s.metadata["homepage_uri"] = s.homepage
  s.metadata["source_code_uri"] = s.homepage

  s.required_ruby_version = ">= 3.1.0"

  s.require_paths = ["lib"]
end

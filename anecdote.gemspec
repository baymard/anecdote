$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "anecdote/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "anecdote"
  s.version     = Anecdote::VERSION
  s.authors     = ["Jamie Appleseed"]
  s.email       = ["jamieappleseed@gmail.com"]
  s.homepage    = "https://github.com/JamieAppleseed/anecdote"
  s.summary     = "General-purpose page layouts"
  s.description = "Provides Raconteur tags and front-end code for general-purpose page layouts"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"
  s.add_dependency "sass-rails"
  s.add_dependency "uglifier"
  s.add_dependency "raconteur"
  s.add_dependency "kramdown"
  s.add_dependency "nokogiri"

  s.add_development_dependency "byebug"
  s.add_development_dependency "minitest"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-minitest"
  s.add_development_dependency "guard-livereload"
  s.add_development_dependency "rack-livereload"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "paperclip"

end

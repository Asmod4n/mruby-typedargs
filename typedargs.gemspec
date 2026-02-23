# typedargs.gemspec
require_relative 'mrblib/version.rb'
Gem::Specification.new do |s|
  s.name          = "typedargs"
  s.version       = TypedArgs::VERSION
  s.summary       = "A tiny, deterministic operator-typed CLI language."
  s.description   = "Pure Ruby implementation of TypedArgs, a small explicit grammar for structured CLI argument parsing. Works on both MRuby and CRuby."
  s.authors       = ["Asmod4n"]
  s.homepage      = "https://github.com/Asmod4n/mruby-typedargs"
  s.license       = "Apache-2.0"

  # RubyGems needs to know what to package.
  s.files = Dir[
    "lib/**/*.rb",
    "mrblib/**/*.rb",
    "README*",
    "LICENSE*"
  ]

  # Ruby loads from lib/, MRuby loads from mrblib/
  s.require_paths = ["lib", "mrblib"]

  # Optional but nice: declare minimum Ruby version
  s.required_ruby_version = ">= 2.5"

  # No runtime dependencies — pure Ruby
end

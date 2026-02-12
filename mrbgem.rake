MRuby::Gem::Specification.new('mruby-typedargs') do |spec|
  spec.license = 'Apache-2'
  spec.author  = 'Hendrik Beskow'
  spec.summary = 'powerfull command-line argument parser for mruby'
  spec.add_test_dependency 'mruby-compiler'

  spec.bins = %w(typedargs_test)
end

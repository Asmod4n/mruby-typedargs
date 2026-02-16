MRuby::Build.new do |conf|
  toolchain :gcc
  enable_debug
  conf.enable_debug
  #conf.enable_sanitizer "address,undefined,leak"
  conf.enable_test
  conf.enable_bintest
  conf.gem File.expand_path(File.dirname(__FILE__))
end
1

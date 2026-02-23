require 'rake'
require 'fileutils'

MRUBY_CONFIG_PATH = File.expand_path(ENV["MRUBY_CONFIG"] || "build_config.rb")

file :mruby do
  unless File.directory?('mruby')
    sh "git clone --depth=1 https://github.com/mruby/mruby.git"
    sh "git submodule update --init --recursive"
  end
end

desc "compile binary"
task :compile => :mruby do
  Dir.chdir("mruby") do
    ENV["MRUBY_CONFIG"] = MRUBY_CONFIG_PATH
    sh "rake all"
  end
end

desc "test mruby"
task :test_mruby => :mruby do
  Dir.chdir("mruby") do
    ENV["MRUBY_CONFIG"] = MRUBY_CONFIG_PATH
    sh "rake all test"
  end
end

desc "test CRuby"
task :test_cruby do
  ruby "-Ilib -Ispec -Itest spec/cruby_tests.rb"
end


desc "cleanup"
task :clean do
  Dir.chdir("mruby") do
    ENV["MRUBY_CONFIG"] = MRUBY_CONFIG_PATH
    sh "rake deep_clean"
  end
end

task :test => [:test_cruby, :test_mruby]

task :default => :test

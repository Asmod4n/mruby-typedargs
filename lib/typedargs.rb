# lib/typedargs.rb
mrblib = File.expand_path("../mrblib", __dir__)

Dir[File.join(mrblib, "*.rb")].sort.each do |file|
  require file
end

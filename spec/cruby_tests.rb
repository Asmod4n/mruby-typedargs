require "minitest/autorun"

module MRubyAssertShim
  def assert(name = nil)
    yield
  end

  def assert_equal(expected, actual)
    raise "Expected #{expected.inspect}, got #{actual.inspect}" unless expected == actual
  end

  def assert_true(value)
    raise "Expected true, got #{value.inspect}" unless value == true
  end

  def assert_nil(value)
    raise "Expected nil, got #{value.inspect}" unless value.nil?
  end

  def assert_raise(error)
    begin
      yield
    rescue error
      return true
    end
    raise "Expected #{error}, but nothing was raised"
  end
end

include MRubyAssertShim

require "typedargs"

Dir[File.join(__dir__, "../test/*.rb")].each do |file|
  require file
end

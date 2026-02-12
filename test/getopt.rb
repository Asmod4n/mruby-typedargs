##
# Universal getopt conformance suite
# Covers only behavior shared by GNU, BSD, POSIX, musl, BusyBox, macOS
#

# -------------------------------------------------------------
# BASIC SHORT FLAGS
# -------------------------------------------------------------
assert("getopt: single short flag") do
  r = TypedArgs.opts("-a")
  assert_true r["a"]
end

assert("getopt: multiple short flags") do
  r = TypedArgs.opts("-a", "-b", "-c")
  assert_true r["a"]
  assert_true r["b"]
  assert_true r["c"]
end

# -------------------------------------------------------------
# SHORT FLAG WITH VALUE
# -------------------------------------------------------------
assert("getopt: short flag with numeric value") do
  r = TypedArgs.opts("-x42")
  assert_equal 42, r["x"]
end

assert("getopt: short flag with string value") do
  r = TypedArgs.opts("-xhello")
  assert_equal "hello", r["x"]
end

assert("getopt: short flag with boolean true") do
  r = TypedArgs.opts("-xtrue")
  assert_equal true, r["x"]
end

assert("getopt: short flag with boolean false") do
  r = TypedArgs.opts("-xfalse")
  assert_equal false, r["x"]
end

# -------------------------------------------------------------
# SHORT FLAG OVERRIDE (NOT ARRAYS)
# -------------------------------------------------------------
assert("getopt: repeated short flag overrides previous") do
  r = TypedArgs.opts("-x1", "-x2", "-x3")
  assert_equal 3, r["x"]
end

# -------------------------------------------------------------
# NEGATIVE NUMBERS
# -------------------------------------------------------------
assert("getopt: negative number") do
  r = TypedArgs.opts("-x-42")
  assert_equal(-42, r["x"])
end

# -------------------------------------------------------------
# INVALID NUMBER FORMAT
# -------------------------------------------------------------
assert("getopt: invalid number format") do
  assert_raise(TypedArgs::InvalidNumberError) do
    TypedArgs.opts("-x12.34.56")
  end
end

# -------------------------------------------------------------
# INVALID SHORT FLAG NAMES
# -------------------------------------------------------------
assert("getopt: invalid short flag name") do
  assert_raise(TypedArgs::InvalidCharacterError) do
    TypedArgs.opts("-!5")
  end
end

# -------------------------------------------------------------
# INVALID SHORT FLAG VALUES
# -------------------------------------------------------------
assert("getopt: invalid short flag value (unterminated string)") do
  assert_raise(TypedArgs::UnterminatedStringError) do
    TypedArgs.opts("-x\"unterminated")
  end
end

# -------------------------------------------------------------
# SHORT FLAG ALIASING (ALLOWED IN YOUR IMPLEMENTATION)
# -------------------------------------------------------------
assert("getopt: short alias to long scalar") do
  TypedArgs.alias("-d", "--debug")
  r = TypedArgs.opts("-d")
  assert_true r["debug"]
end

assert("getopt: short alias with value") do
  TypedArgs.alias("-p", "--port")
  r = TypedArgs.opts("-p8080")
  assert_equal 8080, r["port"]
end

assert("getopt: alias expands to invalid key") do
  TypedArgs.alias("-x", "--bad!key")
  assert_raise(TypedArgs::InvalidCharacterError) do
    TypedArgs.opts("-x")
  end
end

##
# TypedArgs conformance suite
#

# -------------------------------------------------------------
# BASIC SCALARS
# -------------------------------------------------------------
assert("TypedArgs: scalar") do
  r = TypedArgs.opts("--mode=fast")
  assert_equal "fast", r["mode"]
end

assert("TypedArgs: dotted key scalar") do
  r = TypedArgs.opts("--db.user=root")
  assert_equal "root", r["db.user"]
end

# -------------------------------------------------------------
# ARRAY OF SCALARS
# -------------------------------------------------------------
assert("TypedArgs: array scalar") do
  r = TypedArgs.opts("--item+=a", "--item+=b")
  assert_equal ["a","b"], r["item"]
end

# -------------------------------------------------------------
# HASH TUPLES
# -------------------------------------------------------------
assert("TypedArgs: hash tuple") do
  r = TypedArgs.opts("--range:min,max:=5,10")
  assert_equal({"min"=>5,"max"=>10}, r["range"])
end

# -------------------------------------------------------------
# ARRAY OF HASHES
# -------------------------------------------------------------
assert("TypedArgs: array of hashes") do
  r = TypedArgs.opts(
    "--servers+:name,port:=alpha,80",
    "--servers+:name,port:=beta,443"
  )
  assert_equal 2, r["servers"].size
  assert_equal({"name"=>"alpha","port"=>80},  r["servers"][0])
  assert_equal({"name"=>"beta","port"=>443},  r["servers"][1])
end

# -------------------------------------------------------------
# DOTTED KEY + HASH
# -------------------------------------------------------------
assert("TypedArgs: dotted key hash") do
  r = TypedArgs.opts("--db.user:id,name:=1,root")
  assert_equal({"id"=>1,"name"=>"root"}, r["db.user"])
end

# -------------------------------------------------------------
# ALIASES (LONG-FLAG SEMANTICS ONLY)
# -------------------------------------------------------------
assert("alias: short → long boolean") do
  TypedArgs.alias("-v", "--verbose")
  r = TypedArgs.opts("-v")
  assert_true r["verbose"]
end

assert("alias: short → long dotted key") do
  TypedArgs.alias("-u", "--db.user")
  r = TypedArgs.opts("-u")
  assert_true r["db.user"]
end

assert("alias: short toggles, long sets hash") do
  TypedArgs.alias("-r", "--range")
  r = TypedArgs.opts("-r", "--range:min,max:=5,10")
  assert_equal({"min"=>5,"max"=>10}, r["range"])
end

assert("alias: short + long merge scalar") do
  TypedArgs.alias("-d", "--debug")
  r = TypedArgs.opts("-d", "--debug=true")
  assert_equal true, r["debug"]
end

# -------------------------------------------------------------
# INVALID CHARACTERS
# -------------------------------------------------------------
assert("TypedArgs: invalid character in key") do
  assert_raise(TypedArgs::InvalidCharacterError) do
    TypedArgs.opts("--na!me=1")
  end
end

assert("TypedArgs: invalid character in dotted key") do
  assert_raise(TypedArgs::InvalidCharacterError) do
    TypedArgs.opts("--db.us$er=1")
  end
end

# -------------------------------------------------------------
# INVALID KEY START
# -------------------------------------------------------------
assert("TypedArgs: key cannot start with digit") do
  assert_raise(TypedArgs::InvalidKeyStartError) do
    TypedArgs.opts("--1abc=5")
  end
end

assert("TypedArgs: key cannot start with dash") do
  assert_raise(TypedArgs::InvalidCharacterError) do
    TypedArgs.opts("---abc=5")
  end
end

# -------------------------------------------------------------
# INVALID SUFFIX POSITION
# -------------------------------------------------------------
assert("TypedArgs: suffix after ident") do
  assert_raise(TypedArgs::InvalidSuffixPositionError) do
    TypedArgs.opts("--foo+bar=1")
  end
end

assert("TypedArgs: suffix after dotted part") do
  assert_raise(TypedArgs::InvalidSuffixPositionError) do
    TypedArgs.opts("--foo.bar+=1")
  end
end

assert("TypedArgs: double suffix") do
  assert_raise(TypedArgs::InvalidSuffixPositionError) do
    TypedArgs.opts("--foo++=1")
  end
end

assert("TypedArgs: suffix before dot") do
  assert_raise(TypedArgs::InvalidSuffixPositionError) do
    TypedArgs.opts("--foo+.bar=1")
  end
end

# -------------------------------------------------------------
# INVALID FIELD LISTS
# -------------------------------------------------------------
assert("TypedArgs: empty field list") do
  assert_raise(TypedArgs::InvalidFieldListError) do
    TypedArgs.opts("--foo::=1")
  end
end

assert("TypedArgs: trailing comma in field list") do
  assert_raise(TypedArgs::InvalidFieldListError) do
    TypedArgs.opts("--foo:bar,=1,2")
  end
end

assert("TypedArgs: invalid field name") do
  assert_raise(TypedArgs::InvalidCharacterError) do
    TypedArgs.opts("--foo:na!me:=1")
  end
end

# -------------------------------------------------------------
# INVALID TUPLE VALUES
# -------------------------------------------------------------
assert("TypedArgs: tuple arity mismatch (too few)") do
  assert_raise(TypedArgs::ArityMismatchError) do
    TypedArgs.opts("--range:min,max:=5")
  end
end

assert("TypedArgs: tuple arity mismatch (too many)") do
  assert_raise(TypedArgs::ArityMismatchError) do
    TypedArgs.opts("--range:min,max:=5,10,15")
  end
end

# -------------------------------------------------------------
# INVALID SCALAR VALUES
# -------------------------------------------------------------
assert("TypedArgs: unterminated string") do
  assert_raise(TypedArgs::UnterminatedStringError) do
    TypedArgs.opts('--foo="abc')
  end
end

assert("TypedArgs: lone dash is invalid number") do
  assert_raise(TypedArgs::InvalidCharacterError) do
    TypedArgs.opts("--foo=--")
  end
end

assert("TypedArgs: invalid number format") do
  assert_raise(TypedArgs::InvalidNumberError) do
    TypedArgs.opts("--foo=12.34.56")
  end
end

# -------------------------------------------------------------
# INVALID SHORT FLAGS (ONLY AS ALIAS TRIGGERS)
# -------------------------------------------------------------
assert("TypedArgs: short flag invalid key") do
  assert_raise(TypedArgs::InvalidCharacterError) do
    TypedArgs.opts("-!5")
  end
end

assert("TypedArgs: short flag with invalid scalar") do
  assert_raise(TypedArgs::InvalidCharacterError) do
    TypedArgs.opts("-x\"unterminated")
  end
end

# -------------------------------------------------------------
# INVALID DOT PATHS
# -------------------------------------------------------------
assert("TypedArgs: dot without ident") do
  assert_raise(TypedArgs::UnexpectedTokenError) do
    TypedArgs.opts("--foo.=1")
  end
end

assert("TypedArgs: double dot") do
  assert_raise(TypedArgs::UnexpectedTokenError) do
    TypedArgs.opts("--foo..bar=1")
  end
end

# -------------------------------------------------------------
# INVALID EMPTY KEY
# -------------------------------------------------------------
assert("TypedArgs: empty key") do
  assert_raise(TypedArgs::InvalidKeyStartError) do
    TypedArgs.opts("--=5")
  end
end

# -------------------------------------------------------------
# INVALID ALIAS EXPANSION
# -------------------------------------------------------------
assert("TypedArgs: alias expands to invalid key") do
  TypedArgs.alias("-x", "--bad!key")
  assert_raise(TypedArgs::InvalidCharacterError) do
    TypedArgs.opts("-x")
  end
end

assert("TypedArgs: nil literal") do
  r = TypedArgs.opts("--foo=nil")
  assert_nil r["foo"]
  assert_true r.key?("foo")
end

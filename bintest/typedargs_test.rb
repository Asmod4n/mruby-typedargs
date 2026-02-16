require 'open3'

def assert_ta(exp_out, exp_err, exp_success, args)
  out, err, stat = Open3.capture3(*(cmd_list("typedargs_test") + args))
  assert "typedargs #{args.inspect}" do
    assert_operator exp_out, :===, out, "stdout mismatch"
    assert_operator exp_err, :===, err, "stderr mismatch"
    assert_equal exp_success, stat.success?, "exit status mismatch"
  end
end

# ------------------------------------------------------------
# VALID CASES (ASCII ONLY)
# ------------------------------------------------------------

assert('simple key=value') do
  assert_ta(
    /\{"foo" => \{"value" => "bar"\}\}\n/,
    "",
    true,
    ["--foo:value:=bar"]
  )
end

assert('integer parsing') do
  assert_ta(/\{"n" => \{"value" => 123\}\}\n/, "", true, ["--n:value:=123"])
end

assert('float parsing') do
  assert_ta(/\{"f" => \{"value" => 12.34\}\}\n/, "", true, ["--f:value:=12.34"])
end

assert('boolean parsing') do
  assert_ta(/\{"b" => \{"value" => true\}\}\n/, "", true, ["--b:value:=true"])
end

assert('array of scalars') do
  # match compact single-line output
  assert_ta(
    "{\"x\" => [{\"value\" => 1}, {\"value\" => 2}, {\"value\" => 3}]}\n",
    "",
    true,
    [
      "--x+:value:=1",
      "--x+:value:=2",
      "--x+:value:=3"
    ]
  )
end

assert('array of hashes') do
  assert_ta(
    "{\"servers\" => [{\"name\" => \"alpha\", \"port\" => 80}, {\"name\" => \"beta\", \"port\" => 443}]}\n",
    "",
    true,
    [
      "--servers+:name,port:=alpha,80",
      "--servers+:name,port:=beta,443"
    ]
  )
end

# ------------------------------------------------------------
# INVALID CASES (ASCII ONLY)
# ------------------------------------------------------------

# Missing field list (key has colon but no field names)
assert('missing field list') do
  assert_ta("", /Expected IDENT/, false, ["--foo:=bar"])
end

# Missing value after := (value absent)
assert('missing value after :=') do
  assert_ta("", /Unexpected EOF/, false, ["--x:value:="])
end

# Unterminated string (opening quote but no closing quote)
assert('unterminated string') do
  assert_ta("", /Unterminated string/, false, ['--x:value:="hello'])
end


# Invalid number format (multiple dots)
assert('invalid number') do
  assert_ta("", /Invalid number format/, false, ["--x:value:=12.34.56"])
end

# Value with comma but no hash fields (tuple arity mismatch)
assert('value with comma but no hash fields') do
  assert_ta("", /Arity mismatch/, false, ["--x:value:=a,b"])
end

# Plus suffix without array context (invalid field list start)
assert('plus without array context') do
  assert_ta("", /Expected IDENT/, false, ["--x+:=1"])
end

# Dangling comma in hash field list
assert('dangling comma in hash field list') do
  assert_ta("", /Expected IDENT/, false, ["--x:name,port,:=alpha,80"])
end

# Unexpected token in field list (bad punctuation)
assert('unexpected token in field list') do
  assert_ta("", /Expected IDENT/, false, ["--servers+:name,port,=alpha,80"])
end

# Invalid suffix position (suffix not at end)
assert('multiple nested keys invalid suffix position') do
  assert_ta("", /Suffix must be at end of key/, false, ["--a:b:c:value:=1"])
end

# Illegal character in key (single quote or other illegal char)
assert('illegal character in key') do
  assert_ta("", /Illegal character/, false, ["--bad'key:value:=1"])
end

# Invalid short flag name (non-identifier start)
assert('invalid short flag') do
  assert_ta("", /Illegal character in short flag/, false, ["-1x"])
end

# Tuple arity mismatch when quoted field not separated correctly
assert('tuple arity mismatch with quoted element') do
  assert_ta("", /Arity mismatch/, false, ['--srv:name,port:="one element only"'])
end

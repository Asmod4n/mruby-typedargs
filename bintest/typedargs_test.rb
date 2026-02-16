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

# Add this integration test near the other assert_ta tests

assert('integration: full typedargs_test invocation') do
  expected_out = <<'OUT'
{"mode" => "ultra", "db.user" => "admin", "db.pass" => "p@ssw0rd", "item" => ["apple", "banana", "cherry", "date", "elderberry"], "range" => {"min" => 10, "max" => 20}, "servers" => [{"name" => "alpha", "port" => 80}, {"name" => "beta", "port" => 443}, {"name" => "gamma", "port" => 22}, {"name" => "delta", "port" => 8080}, {"name" => "epsilon", "port" => 3306}], "cache.enabled" => true, "cache.timeout" => 99.9, "feature" => [{"name" => "login", "enabled" => true}, {"name" => "signup", "enabled" => false}, {"name" => "notifications", "enabled" => nil}, {"name" => "analytics", "enabled" => true}], "level" => 9001, "ratio" => 3.14159, "verbose" => true, "debug" => nil, "list" => ["one", "two", "three", "four", "five"], "coords" => {"x" => 7, "y" => 8, "z" => 9}, "extra" => [{"id" => 1001, "value" => "foo"}, {"id" => 1002, "value" => "bar"}, {"id" => 1003, "value" => "baz"}, {"id" => 1004, "value" => "qux"}, {"id" => 1005, "value" => "quux"}], "v" => true, "d" => true, "x" => true, "y" => true}
OUT

  args = [
    "--mode=ultra",
    "--db.user=admin",
    "--db.pass=p@ssw0rd",
    "--item+=apple", "--item+=banana", "--item+=cherry", "--item+=date", "--item+=elderberry",
    "--range:min,max:=10,20",
    "--servers+:name,port:=alpha,80", "--servers+:name,port:=beta,443", "--servers+:name,port:=gamma,22",
    "--servers+:name,port:=delta,8080", "--servers+:name,port:=epsilon,3306",
    "--cache.enabled=true", "--cache.timeout=99.9",
    "--feature+:name,enabled:=login,true", "--feature+:name,enabled:=signup,false",
    "--feature+:name,enabled:=notifications,nil", "--feature+:name,enabled:=analytics,true",
    "--level=9001", "--ratio=3.14159",
    "--verbose", "--debug=nil",
    "--list+=one", "--list+=two", "--list+=three", "--list+=four", "--list+=five",
    "--coords:x,y,z:=1,2,3", "--coords:x,y,z:=4,5,6", "--coords:x,y,z:=7,8,9",
    "--extra+:id,value:=1001,foo", "--extra+:id,value:=1002,bar", "--extra+:id,value:=1003,baz",
    "--extra+:id,value:=1004,qux", "--extra+:id,value:=1005,quux",
    "-v", "-d", "-x", "-y"
  ]

  assert_ta(expected_out, "", true, args)
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

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
    %w[--foo:value:=bar]
  )
end

assert('integer parsing') do
  assert_ta(/\{"n" => \{"value" => 123\}\}\n/, "", true, %w[--n:value:=123])
end

assert('float parsing') do
  assert_ta(/\{"f" => \{"value" => 12.34\}\}\n/, "", true, %w[--f:value:=12.34])
end

assert('boolean parsing') do
  assert_ta(/\{"b" => \{"value" => true\}\}\n/, "", true, %w[--b:value:=true])
end

assert('array of scalars') do
  assert_ta(
    /\{"x" => \[\{"value" => 1\}, \{"value" => 2\}, \{"value" => 3\}\]\}\n/,
    "",
    true,
    %w[--x+:value:=1 --x+:value:=2 --x+:value:=3]
  )
end

assert('array of hashes') do
  assert_ta("{\"servers\" => [{\"name\" => \"alpha\", \"port\" => 80}, {\"name\" => \"beta\", \"port\" => 443}]}\n",
    "",
    true,
    %w[
      --servers+:name,port:=alpha,80
      --servers+:name,port:=beta,443
    ]
  )
end

# ------------------------------------------------------------
# INVALID CASES (ASCII ONLY)
# ------------------------------------------------------------

assert('missing field list') do
  assert_ta("", /Expected IDENT/, false, %w[--foo:=bar])
end

assert('missing value after :=') do
  assert_ta("", /Unexpected EOF/, false, %w[--x:value:=])
end

assert('unterminated string') do
  assert_ta("", /Unterminated string/, false, %w[--x:value:="hello])
end

assert('invalid number') do
  assert_ta("", /Invalid number format/, false, %w[--x:value:=12.34.56])
end

assert('value with comma but no hash fields') do
  assert_ta("", /Arity mismatch/, false, %w[--x:value:=a,b])
end

assert('plus without array context') do
  assert_ta("", /Expected IDENT/, false, %w[--x+:=1])
end

assert('dangling comma in hash field list') do
  assert_ta("", /Expected IDENT/, false, %w[--x:name,port,:=alpha,80])
end

assert('unexpected token in field list') do
  assert_ta("", /Expected IDENT/, false, %w[--servers+:name,port,=alpha,80])
end

assert('multiple nested keys (invalid suffix position)') do
  assert_ta("", /Suffix must be at end of key/, false, %w[--a:b:c:value:=1])
end

assert('empty ARGV') do
  assert_ta(/\{\}\n/, "", true, [])
end

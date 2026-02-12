# TypedArgs

TypedArgs is a tiny, explicit, suffix‑typed command‑line grammar implemented in pure MRuby‑core‑friendly Ruby.
It can run inside a fully sandboxed MRuby VM with no dependencies, no shell tricks, and no reliance on host environment behavior.

TypedArgs is not an “option parser.”
It is a mini‑language for structured CLI data.

You get:

- Scalar values
- Arrays (--item+=value)
- Hash tuples (--range:min,max:=5,10)
- Arrays of hashes (--servers+:name,port:=alpha,80)
- Dotted keys (--db.user=root)
- Short‑flag aliases (TypedArgs.alias("-v", "--verbose"))
- Precise syntax errors with caret diagnostics
- Full portability across shells and platforms

TypedArgs behaves the same everywhere — Linux, macOS, Windows, embedded systems, containers, CI runners, BusyBox, Alpine, and any MRuby host.

---

## Installation

TypedArgs is pure Ruby and requires only MRuby core.
Just include the Ruby files in your MRuby build or load them into your MRuby VM.

---

## Basic Usage
```ruby
args = TypedArgs.opts("--mode=fast", "--debug=true")

args["mode"]   # => "fast"
args["debug"]  # => true
```
If no arguments are passed, TypedArgs.opts defaults to ARGV. You have to supply that Array yourself, take a look at tools/typedargs_test/test.c how to set that up.

---

# Grammar Overview

TypedArgs defines a small, explicit grammar for keys and values.

---

## Scalars
```
--mode=fast
--count=5
--debug=true
```
Values may be:
- strings
- integers
- floats
- booleans (true / false)

---

## Dotted Keys
```
--db.user=root
--cache.redis.host=localhost
```
Keys may contain letters, digits, underscore, dash, and dot.
Keys may not start with a digit or dash.

---

## Arrays
```
--item+=a
--item+=b
```
Result:
```ruby
{ "item" => ["a", "b"] }
```
---

## Hash Tuples
```
--range:min,max:=5,10
```
Result:
```ruby
{ "range" => { "min" => 5, "max" => 10 } }
```
Arity is enforced: if you declare two fields, you must supply two values.

---

## Arrays of Hashes
```
--servers+:name,port:=alpha,80
--servers+:name,port:=beta,443
```
Result:
```ruby
{
  "servers" => [
    { "name" => "alpha", "port" => 80 },
    { "name" => "beta",  "port" => 443 }
  ]
}
```
---

## Short‑Flag Aliases
```ruby
TypedArgs.alias("-v", "--verbose")
TypedArgs.opts("-v")
# => { "verbose" => true }
```
Aliases expand before parsing and can target dotted keys.

---

## Error Reporting

TypedArgs provides compiler‑style diagnostics with caret indicators.

Example:
```
--range:min,max:=5
                 ^
Syntax error: Arity mismatch: expected 2, got 1
```
Every error includes:
- the original argument
- a caret pointing to the exact byte
- a clear error class

TypedArgs is self‑teaching.

---

## Design Philosophy

TypedArgs is intentionally:

- Explicit — no guessing, no heuristics
- Portable — no reliance on shell features
- Minimal — a tiny grammar with predictable rules
- Typed — arrays, hashes, and tuples are first‑class
- Deterministic — the same input always produces the same structure

TypedArgs does NOT depend on:
- shell brace expansion
- shell quoting rules
- environment‑specific behavior
- Bash‑only features

The shell’s only job is to pass raw strings.
TypedArgs does everything else.

---

## Conformance Suite

TypedArgs ships with a full conformance suite covering:

- scalars
- arrays
- hashes
- arrays of hashes
- dotted keys
- alias expansion
- invalid characters
- invalid suffix placement
- invalid field lists
- tuple arity
- invalid numbers
- unterminated strings
- invalid short flags
- invalid dotted paths
- empty keys
- alias expansion to invalid keys

This suite defines the language.

---

# TypedArgs Operator Cheat Sheet

TypedArgs applies **flags in order**. Later flags **overwrite previous values**, except when using explicit accumulation operators (`+=` / `+:fields:=`).  
This cheat sheet summarizes all major operator behaviors with examples.

---

## 1️⃣ Scalar Assignment

| Syntax         | Description                     | Example                     | Result                          |
|----------------|---------------------------------|-----------------------------|--------------------------------|
| `--key=value`  | Assign a scalar value            | `--foo=1`                  | `{ "foo" => 1 }`               |
| `--key=true`   | Boolean assignment               | `--verbose=true`           | `{ "verbose" => true }`        |

> Overwrites previous value, regardless of type.

---

## 2️⃣ Scalar Accumulation (`+=`)

| Syntax         | Description                     | Example                     | Result                          |
|----------------|---------------------------------|-----------------------------|--------------------------------|
| `--key+=value` | Append scalar to array           | `--foo+=2`                  | `{ "foo" => [2] }`             |
|                |                                 | `--foo=1` <br> `--foo+=2`  | `{ "foo" => [2] }`             |

> **Important:**  
> - `+=` creates an array containing the appended value.  
> - If the previous value was scalar or hash, it is **overwritten**.  
> - Accumulation only works if the last operator is also `+=` (see below).

---

## 3️⃣ Hash Tuple Assignment (`:=`)

| Syntax                   | Description                     | Example                                 | Result                           |
|--------------------------|---------------------------------|-----------------------------------------|---------------------------------|
| `--key:field1,field2:=v1,v2` | Assign multiple values to hash | `--range:min,max:=5,10`                 | `{ "range" => { "min"=>5, "max"=>10 } }` |
|                          | Dotted keys allowed       | `--db.user:id,name:=1,root`     | `{ "db.user" => { "id"=>1, "name"=>"root" } }` |

> Overwrites any previous scalar, array, or hash.

---

## 4️⃣ Array of Hashes (`+:fields:=values`)

| Syntax                           | Description                     | Example                                         | Result                                      |
|----------------------------------|---------------------------------|-------------------------------------------------|---------------------------------------------|
| `--key+:field1,field2:=v1,v2`    | Append a hash to an array       | `--servers+:name,port:=alpha,80`                | `[{"name"=>"alpha","port"=>80}]`            |
| `--servers+:name,port:=beta,443` |Multiple append                  |                                                 | `[{"name"=>"alpha","port"=>80}, {"name"=>"beta","port"=>443}]` |

> Creates array if key doesn’t exist. Only appends when using `+:` operator.  

---

## 5️⃣ Sequential Override Rules

- **Later flags overwrite earlier flags** unless using accumulation operators.  
- **Operator type determines the final value type**:

| Sequence                                         | Result                  |
|-------------------------------------------------|------------------------|
| `--foo=1` <br> `--foo+=2`                       | `[2]`                  |
| `--foo+=1` <br> `--foo+=2`                      | `[1,2]`                |
| `--foo:min,max:=1,2` <br> `--foo:min,max:=3,4`  | `{ "min"=>3,"max"=>4 }`|
| `--foo+:min,max:=1,2` <br> `--foo+:min,max:=3,4`| `[{"min"=>1,"max"=>2},{"min"=>3,"max"=>4}]`|
| `--foo=1` <br> `--foo+=2` <br> `--foo:name:=alpha` <br> `--foo=bar` | `"bar"` |

> Key points:  
> - `=` and `:=` **always overwrite previous values**.  
> - `+=` and `+:` **append only if previous value is of the same accumulation kind**.  
> - Dotted keys are treated as **flat strings**, not nested hashes.

---

## 6️⃣ Summary Table: Operator Semantics

| Operator      | Accumulates? | Overwrites previous? | Creates container if missing? | Example |
|---------------|-------------|-------------------|-------------------------------|---------|
| `=`           | ❌          | ✅                | ❌                            | `--foo=1` → `1` |
| `+=`          | ✅ (arrays) | ✅ if type differs | ✅                            | `--foo+=2` → `[2]` |
| `:=`          | ❌          | ✅                | ✅ (hash)                     | `--range:min,max:=5,10` → `{"min"=>5,"max"=>10}` |
| `+:fields:=`  | ✅ (arrays of hashes) | ✅ if type differs | ✅ (array)                   | `--servers+:name,port:=alpha,80` → `[{"name"=>"alpha","port"=>80}]` |

---

## 7️⃣ Notes & Recommendations

1. **Sequential order matters**: flags are applied in the order received.  
2. **Last-assignment-wins** unless explicit accumulation is used.  
3. **Mixing types**: a scalar followed by an accumulation operator resets the type.  
4. **Aliases**: short flags expand to long flags and follow the same rules.  
5. **Dotted keys**: treated as flat strings; no implicit nesting.  

---

## License

Apache-2

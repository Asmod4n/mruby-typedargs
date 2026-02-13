# TypedArgs  
*A tiny operator‑typed CLI language for structured data.*

TypedArgs is not an option parser.  
It is a **mini‑language** for expressing structured data on the command line — scalars, arrays, hashes, and arrays of hashes — using a small set of explicit, shell‑safe operators.

It runs anywhere MRuby runs: embedded systems, containers, CI runners, Windows, macOS, Linux, BusyBox, Alpine, and fully sandboxed MRuby VMs. No dependencies. No shell tricks. No heuristics. No guessing.

TypedArgs behaves the same everywhere.

---

# Why TypedArgs Exists

Most CLI parsers try to *guess* what the user meant. TypedArgs refuses.  
Shells are inconsistent. Quoting rules differ. JSON on the command line is painful.  
Suffix‑typed flags collide with shells. YAML is too heavy.  
Users deserve a grammar that is:

- **Explicit** — the operator defines the shape  
- **Portable** — works in every shell without quoting  
- **Deterministic** — same input, same output, always  
- **Minimal** — four operators, one mental model  
- **Structured** — arrays and hashes are first‑class citizens  

TypedArgs is the answer: a tiny algebra of flags.

---

# The Operator Model

TypedArgs is built on four operators.  
They define the shape of the value — nothing else is needed.

| Operator | Meaning |
|----------|---------|
| `=` | scalar assignment |
| `+=` | append scalar to array |
| `:fields:=` | assign hash tuple |
| `+:fields:=` | append hash tuple to array |

This is the entire language.

No suffixes.  
No brackets.  
No type inference.  
No shell‑sensitive characters.  
Just operators.

---

# Installation

TypedArgs is pure Ruby and MRuby‑core‑friendly.  
Drop the Ruby files into your MRuby build or load them into your VM.

---

# Basic Usage

```ruby
args = TypedArgs.opts("--mode=fast", "--debug=true")

args["mode"]   # => "fast"
args["debug"]  # => true
```

If no arguments are passed, `TypedArgs.opts` defaults to `ARGV`.  
You must supply that array yourself in MRuby; see `tools/typedargs_test/test.c` for an example.

---

# Grammar Overview

TypedArgs defines a small, explicit grammar for keys and values.  
Everything is driven by operators.

---

## Scalars

```
--mode=fast
--count=5
--debug=true
--foo=nil
```

Values may be:

- strings  
- integers  
- floats  
- booleans (`true` / `false`)  
- `nil`  

---

## Dotted Keys

```
--db.user=root
--cache.redis.host=localhost
```

Keys may contain:

- letters  
- digits  
- underscore  
- dash  
- dot  

Keys may **not** start with a digit or dash.  
Dotted keys are treated as **flat strings**, not nested hashes.

---

## Arrays (`+=`)

```
--item+=a
--item+=b
```

Result:

```ruby
{ "item" => ["a", "b"] }
```

`+=` always appends.  
If the key didn’t exist, an array is created.

---

## Hash Tuples (`:fields:=`)

```
--range:min,max:=5,10
```

Result:

```ruby
{ "range" => { "min" => 5, "max" => 10 } }
```

Arity is enforced:  
If you declare two fields, you must supply two values.

---

## Arrays of Hashes (`+:fields:=`)

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

`+:` always appends a hash to an array.

---

## Short‑Flag Aliases

```ruby
TypedArgs.alias("-v", "--verbose")
TypedArgs.opts("-v")
# => { "verbose" => true }
```

Aliases expand before parsing.  
They can target dotted keys and any operator form.

---

# Error Reporting

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

# Operator Semantics

TypedArgs applies flags **in order**.  
Later flags overwrite earlier ones unless using accumulation operators.

---

## Scalar Assignment (`=`)

| Syntax | Meaning |
|--------|---------|
| `--key=value` | assign scalar |

Overwrites previous value.

---

## Scalar Accumulation (`+=`)

| Syntax | Meaning |
|--------|---------|
| `--key+=value` | append scalar to array |

Creates array if missing.  
Overwrites previous non‑array values.

---

## Hash Tuple Assignment (`:fields:=`)

| Syntax | Meaning |
|--------|---------|
| `--key:field1,field2:=v1,v2` | assign hash |

Overwrites previous value.

---

## Array of Hashes (`+:fields:=`)

| Syntax | Meaning |
|--------|---------|
| `--key+:field1,field2:=v1,v2` | append hash to array |

Creates array if missing.

---

# Sequential Override Rules

| Sequence | Result |
|----------|--------|
| `--foo=1` → `--foo+=2` | `[2]` |
| `--foo+=1` → `--foo+=2` | `[1,2]` |
| `--foo:min,max:=1,2` → `--foo:min,max:=3,4` | `{ "min"=>3,"max"=>4 }` |
| `--foo+:min,max:=1,2` → `--foo+:min,max:=3,4` | `[{"min"=>1,"max"=>2},{"min"=>3,"max"=>4}]` |
| `--foo=1` → `--foo+=2` → `--foo:name:=alpha` → `--foo=bar` | `"bar"` |

TypedArgs is explicit:  
the operator determines the shape.

---

# Conformance Suite

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

The suite **is the specification**.  
If an implementation passes the suite, it is TypedArgs.

---

# Design Philosophy

TypedArgs is intentionally:

- **Explicit** — no guessing  
- **Portable** — no shell dependencies  
- **Minimal** — four operators, one grammar  
- **Deterministic** — predictable and stable  
- **Structured** — arrays and hashes are first‑class  

TypedArgs does **not** depend on:

- shell brace expansion  
- shell quoting rules  
- environment‑specific behavior  
- Bash‑only features  

The shell’s only job is to pass raw strings.  
TypedArgs does everything else.

---

# License

Apache‑2

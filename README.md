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

args = TypedArgs.opts("--mode=fast", "--debug=true")

args["mode"]   # => "fast"
args["debug"]  # => true

If no arguments are passed, TypedArgs.opts defaults to ARGV. You have to supply that Array yourself, take a look at tools/typedargs_test/test.c how to set that up.

---

# Grammar Overview

TypedArgs defines a small, explicit grammar for keys and values.

---

## Scalars

--mode=fast
--count=5
--debug=true

Values may be:
- strings
- integers
- floats
- booleans (true / false)

---

## Dotted Keys

--db.user=root
--cache.redis.host=localhost

Keys may contain letters, digits, underscore, dash, and dot.
Keys may not start with a digit or dash.

---

## Arrays

--item+=a
--item+=b

Result:
{ "item" => ["a", "b"] }

---

## Hash Tuples

--range:min,max:=5,10

Result:
{ "range" => { "min" => 5, "max" => 10 } }

Arity is enforced: if you declare two fields, you must supply two values.

---

## Arrays of Hashes

--servers+:name,port:=alpha,80
--servers+:name,port:=beta,443

Result:
{
  "servers" => [
    { "name" => "alpha", "port" => 80 },
    { "name" => "beta",  "port" => 443 }
  ]
}

---

## Short‑Flag Aliases

TypedArgs.alias("-v", "--verbose")
TypedArgs.opts("-v")
# => { "verbose" => true }

Aliases expand before parsing and can target dotted keys.

---

## Error Reporting

TypedArgs provides compiler‑style diagnostics with caret indicators.

Example:

--range:min,max:=5
                 ^
Syntax error: Arity mismatch: expected 2, got 1

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

## License

Apache-2

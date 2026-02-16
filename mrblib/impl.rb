module TypedArgs
  module Internal
    module Impl
      class << self
        def parse(argv)
          out = {}
          i = 0
          n = argv.size
          while i < n
            a = argv[i]
            if a && a.length > 0
              if long_flag?(a)
                parse_long(out, a)
              elsif short_flag?(a)
                parse_short(out, a)
              end
            end
            i += 1
          end
          out
        end

        private
        def long_flag?(arg)
          arg.length >= 2 &&
          arg[0,1] == "-" &&
          arg[1,1] == "-"
        end

        def short_flag?(arg)
          arg.length >= 1 &&
          arg[0,1] == "-" &&
          !(arg.length >= 2 && arg[1,1] == "-")
        end


        # In impl.rb, replace parse_long or parse_long-like logic with:

        def parse_long(out, arg)
          # body as character substring (character-mode)
          body = arg[2, arg.length - 2]   # "--" removed, character-based

          # find '=' in character mode
          eq_idx = body.index("=")

          if eq_idx
            key_str = body[0, eq_idx]    # character substring for key
            val_str = body[(eq_idx + 1), body.length - (eq_idx + 1)] # character substring for value
          else
            key_str = body
            val_str = nil
          end

          # parse key in character mode
          key_lex = Lexer.new(key_str, 0, key_str.length, true)
          key_ast = KeyParser.new(key_lex).parse

          name = Internal.resolve_name(key_ast[:name])

          # script check (character indices)
          ScriptCheck.validate_key(key_str)

          if val_str
            # parse value in character mode (value lexer now also character-based)
            val_lex = Lexer.new(val_str, 0, val_str.length, false)
            vp = ValueParser.new(val_lex)

            case key_ast[:kind]
            when :scalar, :array_scalar
              value = vp.parse_scalar
            when :hash, :array_hash
              tuple = vp.parse_tuple(key_ast[:fields].size)
              value = build_hash(key_ast[:fields], tuple)
            end
          else
            value = true
          end

          assign(out, name, key_ast, value)
        end


        def parse_short(out, arg)
          raw  = arg[0,2]
          name = Internal.resolve_name(raw)

          if name.nil? || name.length == 0
            raise TypedArgs::InvalidKeyStartError.new(
              "Invalid key start",
              1,
              arg
            )
          end

          # first character validation (character-mode)
          c0 = name[0,1]
          unless c0 == "_" ||
                (c0 >= "A" && c0 <= "Z") ||
                (c0 >= "a" && c0 <= "z") ||
                (c0 > "\u007F") # treat non-ASCII single-char as letter candidate
            raise TypedArgs::InvalidCharacterError.new(
              "Illegal character in short flag",
              1,
              arg
            )
          end

          # remaining characters validation (character-mode)
          j = 1
          while j < name.length
            ch = name[j,1]
            valid =
              ch == "_" ||
              (ch >= "A" && ch <= "Z") ||
              (ch >= "a" && ch <= "z") ||
              (ch >= "0" && ch <= "9") ||
              ch == "-" ||
              ch == "." ||
              (ch > "\u007F") # allow non-ASCII letters
            unless valid
              raise TypedArgs::InvalidCharacterError.new(
                "Illegal character in short flag",
                1,
                arg
              )
            end
            j += 1
          end

          # attached value (character-mode)
          if arg.length > 2
            val_str = arg[2, arg.length - 2]
            val_lex = Lexer.new(val_str, 0, val_str.length, false)
            vp      = ValueParser.new(val_lex)
            value   = vp.parse_scalar
          else
            value = true
          end

          out[name] = value
        end


        def build_hash(fields, vals)
          h = {}
          i = 0
          while i < fields.size
            h[fields[i]] = vals[i]
            i += 1
          end
          h
        end

        def assign(out, name, spec, value)
          case spec[:kind]
          when :scalar
            out[name] = value
          when :hash
            existing = out[name]
            h = existing.is_a?(Hash) ? existing : {}
            value.each { |k, v| h[k] = v }
            out[name] = h
          when :array_scalar
            existing = out[name]
            arr = existing.is_a?(Array) ? existing : []
            arr.push(value)
            out[name] = arr
          when :array_hash
            existing = out[name]
            arr = existing.is_a?(Array) ? existing : []
            arr.push(value)
            out[name] = arr
          end
        end
      end
    end
  end
end

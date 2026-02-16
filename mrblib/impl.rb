module TypedArgs
  module Internal
    module Impl
      class << self
        def parse(argv)
          out = {}
          i = 0
          while i < argv.size
            arg = argv[i]
            if long_flag?(arg)
              parse_long(out, arg)
            elsif short_flag?(arg)
              parse_short(out, arg)
            end
            i += 1
          end
          out
        end

        def long_flag?(arg)
          arg.bytesize >= 2 &&
          arg.getbyte(0) == CHAR_DASH &&
          arg.getbyte(1) == CHAR_DASH
        end

        def short_flag?(arg)
          arg.bytesize >= 1 &&
          arg.getbyte(0) == CHAR_DASH &&
          !(arg.bytesize >= 2 && arg.getbyte(1) == CHAR_DASH)
        end

        def parse_long(out, arg)
          body_start = 2
          body_len   = arg.bytesize - 2
          body       = arg[body_start, body_len]
          eq         = body.index("=")

          if eq
            key_len   = eq
            val_start = body_start + eq + 1
            val_len   = arg.bytesize - val_start
          else
            key_len   = body_len
            val_start = nil
            val_len   = 0
          end

          key_lexer = Lexer.new(arg, body_start, key_len, true)
          key_ast   = KeyParser.new(key_lexer).parse

          name = Internal.resolve_name(key_ast[:name])

          unless Internal.valid_key_script?(name)
            raise TypedArgs::InvalidCharacterError.new(
              "Invalid or mixed-script key",
              0,
              name
            )
          end

          if val_start
            val_lexer = Lexer.new(arg, val_start, val_len)
            vp        = ValueParser.new(val_lexer)

            case key_ast[:kind]
            when :scalar
              value = vp.parse_scalar
            when :array_scalar
              value = vp.parse_scalar
            when :hash
              tuple = vp.parse_tuple(key_ast[:fields].size)
              value = build_hash(key_ast[:fields], tuple)
            when :array_hash
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

          if name.nil? || name.bytesize == 0
            raise TypedArgs::InvalidKeyStartError.new(
              "Invalid key start",
              1,
              arg
            )
          end

          c0 = name.getbyte(0)
          unless Internal.alpha?(c0) || c0 == CHAR_UNDERS
            raise TypedArgs::InvalidCharacterError.new(
              "Illegal character in short flag",
              1,
              arg
            )
          end

          j = 1
          while j < name.bytesize
            c = name.getbyte(j)
            unless Internal.alpha?(c) ||
                   Internal.digit?(c) ||
                   c == CHAR_UNDERS || c == CHAR_DASH || c == CHAR_DOT
              raise TypedArgs::InvalidCharacterError.new(
                "Illegal character in short flag",
                1,
                arg
              )
            end
            j += 1
          end

          if arg.bytesize > 2
            val_start = 2
            val_len   = arg.bytesize - 2
            val_lexer = Lexer.new(arg, val_start, val_len)
            vp        = ValueParser.new(val_lexer)
            value     = vp.parse_scalar
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

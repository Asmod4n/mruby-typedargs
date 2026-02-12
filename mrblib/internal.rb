module TypedArgs
  module Internal
    CHAR_COMMA  = ",".getbyte(0)   # 44
    CHAR_EQUAL  = "=".getbyte(0)   # 61
    CHAR_DOT    = ".".getbyte(0)   # 46
    CHAR_PLUS   = "+".getbyte(0)   # 43
    CHAR_COLON  = ":".getbyte(0)   # 58
    CHAR_QUOTE  = "\"".getbyte(0)  # 34
    CHAR_DASH   = "-".getbyte(0)   # 45
    CHAR_UNDERS = "_".getbyte(0)   # 95

    CHAR_0 = "0".getbyte(0)
    CHAR_9 = "9".getbyte(0)
    CHAR_A = "A".getbyte(0)
    CHAR_Z = "Z".getbyte(0)
    CHAR_a = "a".getbyte(0)
    CHAR_z = "z".getbyte(0)

    def self.alpha?(c)
      (c >= CHAR_A && c <= CHAR_Z) || (c >= CHAR_a && c <= CHAR_z)
    end

    def self.digit?(c)
      c >= CHAR_0 && c <= CHAR_9
    end

    @alias_map = {}

    class << self
      def register_alias(short, long)
        @alias_map[short] = long
      end

      def strip_leading_dashes(str)
        i = 0
        n = str.bytesize
        while i < n && str.getbyte(i) == 45 # '-'
          i += 1
        end
        str[i, n - i]
      end

      def resolve_name(raw)
        mapped = @alias_map[raw]
        if mapped
          strip_leading_dashes(mapped)
        else
          strip_leading_dashes(raw)
        end
      end
    end

    # ============================================================
    # TOKEN
    # ============================================================
    class Token
      attr_accessor :type, :value, :pos

      def initialize(type, value, pos)
        @type  = type
        @value = value
        @pos   = pos
      end
    end

    # ============================================================
    # LEXER
    # ============================================================
    class Lexer
      attr_reader :str

      def initialize(str, start_pos, bytesize)
        @str   = str
        @i     = start_pos
        @start = start_pos
        @end   = start_pos + bytesize
        @n     = str.bytesize
        @end   = @n if @end > @n
      end

      def next_token
        skip_ws
        return Token.new(:EOF, nil, @i) if @i >= @end

        c = @str.getbyte(@i)

        case c
        when CHAR_COMMA then return simple(:COMMA)
        when CHAR_EQUAL then return simple(:EQUAL)
        when CHAR_DOT   then return simple(:DOT)
        when CHAR_PLUS  then return simple(:PLUS)
        when CHAR_COLON then return simple(:COLON)
        when CHAR_QUOTE then return string_token
        else
          if ident_start?(c)
            return ident_token
          elsif Internal.digit?(c) || c == CHAR_DASH
            return number_token
          else
            raise TypedArgs::InvalidCharacterError.new(
              "Illegal character '" + safe_chr + "'",
              @i,
              @str
            )
          end
        end
      end

      private

      def safe_chr
        return "?" if @i < 0 || @i >= @n
        @str[@i, 1]
      end

      def simple(type)
        tok = Token.new(type, nil, @i)
        @i += 1
        tok
      end

      def skip_ws
        while @i < @end && @str.getbyte(@i) <= 32
          @i += 1
        end
      end

      def string_token
        start = @i
        @i += 1
        buf = ""
        while @i < @end
          c = @str.getbyte(@i)
          if c == CHAR_QUOTE
            @i += 1
            return Token.new(:STRING, buf, start)
          else
            buf = buf + @str[@i, 1]
            @i += 1
          end
        end
        raise TypedArgs::UnterminatedStringError.new(
          "Unterminated string",
          start,
          @str
        )
      end

      def ident_start?(c)
        Internal.alpha?(c) || c == CHAR_UNDERS
      end

      def ident_continue?(c)
        Internal.alpha?(c) ||
        Internal.digit?(c) ||
        c == CHAR_UNDERS || c == CHAR_DASH || c == CHAR_DOT
      end

      def ident_token
        start = @i
        buf   = ""

        c = @str.getbyte(@i)
        unless ident_start?(c)
          raise TypedArgs::InvalidKeyStartError.new(
            "Invalid key start",
            @i,
            @str
          )
        end
        buf = buf + @str[@i, 1]
        @i += 1

        while @i < @end
          c = @str.getbyte(@i)
          break unless ident_continue?(c)
          buf = buf + @str[@i, 1]
          @i += 1
        end

        Token.new(:IDENT, buf, start)
      end

      def number_token
        start = @i
        buf   = ""
        dot   = false

        if @str.getbyte(@i) == CHAR_DASH
          buf = buf + "-"
          @i += 1
        end

        while @i < @end
          c = @str.getbyte(@i)
          if Internal.digit?(c)
            buf = buf + @str[@i, 1]
            @i += 1
          elsif c == CHAR_DOT
            if dot
              raise TypedArgs::InvalidNumberError.new(
                "Invalid number format",
                start,
                @str
              )
            end
            dot = true
            buf = buf + "."
            @i += 1
          else
            break
          end
        end

        if dot
          Token.new(:NUMBER, buf.to_f, start)
        else
          Token.new(:NUMBER, buf.to_i, start)
        end
      end
    end

    # ============================================================
    # KEY PARSER
    # ============================================================
    class KeyParser
      def initialize(lexer)
        @lx  = lexer
        @tok = @lx.next_token
      end

      def parse
        key    = parse_key_string
        array  = false
        fields = nil

        # structural dot validation
        if key.bytesize > 0 && key.getbyte(key.bytesize - 1) == CHAR_DOT
          raise TypedArgs::UnexpectedTokenError.new(
            "Expected IDENT after DOT",
            0,
            @lx.str
          )
        end

        i = 0
        while i + 1 < key.bytesize
          if key.getbyte(i) == CHAR_DOT && key.getbyte(i + 1) == CHAR_DOT
            raise TypedArgs::UnexpectedTokenError.new(
              "Unexpected DOT",
              0,
              @lx.str
            )
          end
          i += 1
        end

        if key.index(".") && @tok.type == :PLUS
          raise TypedArgs::InvalidSuffixPositionError.new(
            "Suffix must be at end of key",
            @tok.pos,
            @lx.str
          )
        end

        if @tok.type == :PLUS
          consume(:PLUS)
          array = true
        end

        if @tok.type == :COLON
          consume(:COLON)
          fields = parse_ident_list
          consume(:COLON)
        end

        if @tok.type == :PLUS || @tok.type == :COLON || @tok.type == :IDENT || @tok.type == :DOT
          raise TypedArgs::InvalidSuffixPositionError.new(
            "Suffix must be at end of key",
            @tok.pos,
            @lx.str
          )
        end

        kind =
          if array && fields then :array_hash
          elsif array        then :array_scalar
          elsif fields       then :hash
          else                   :scalar
          end

        { name: key, kind: kind, fields: fields }
      end

      private

      def parse_key_string
        if @tok.type != :IDENT
          raise TypedArgs::InvalidKeyStartError.new(
            "Invalid key start",
            @tok.pos,
            @lx.str
          )
        end

        first = expect(:IDENT).value
        buf   = first

        while @tok.type == :DOT
          consume(:DOT)
          if @tok.type != :IDENT
            raise TypedArgs::UnexpectedTokenError.new(
              "Expected IDENT, got " + @tok.type.to_s,
              @tok.pos,
              @lx.str
            )
          end
          part = expect(:IDENT).value
          buf = buf + "." + part
        end

        buf
      end

      def parse_ident_list
        list = []
        if @tok.type != :IDENT
          raise TypedArgs::InvalidFieldListError.new(
            "Expected IDENT",
            @tok.pos,
            @lx.str
          )
        end
        list.push(expect(:IDENT).value)
        while @tok.type == :COMMA
          consume(:COMMA)
          if @tok.type != :IDENT
            raise TypedArgs::InvalidFieldListError.new(
              "Expected IDENT",
              @tok.pos,
              @lx.str
            )
          end
          list.push(expect(:IDENT).value)
        end
        list
      end

      def expect(type)
        if @tok.type != type
          raise TypedArgs::UnexpectedTokenError.new(
            "Expected " + type.to_s + ", got " + @tok.type.to_s,
            @tok.pos,
            @lx.str
          )
        end
        tok = @tok
        @tok = @lx.next_token
        tok
      end

      def consume(type)
        expect(type)
      end
    end

    # ============================================================
    # VALUE PARSER
    # ============================================================
    class ValueParser
      def initialize(lexer)
        @lx  = lexer
        @tok = @lx.next_token
      end

      def parse_tuple(expected)
        vals = []
        vals.push(parse_scalar)
        while @tok.type == :COMMA
          consume(:COMMA)
          vals.push(parse_scalar)
        end
        if vals.size != expected
          raise TypedArgs::ArityMismatchError.new(
            "Arity mismatch: expected " + expected.to_s + ", got " + vals.size.to_s,
            @tok.pos,
            @lx.str
          )
        end
        vals
      end

      def parse_scalar
        case @tok.type
        when :STRING
          v = @tok.value
          consume(:STRING)
          v
        when :NUMBER
          v = @tok.value
          consume(:NUMBER)
          v
        when :IDENT
          v = @tok.value
          consume(:IDENT)
          return true  if v == "true"
          return false if v == "false"
          return nil if v == "nil"
          v
        else
          raise TypedArgs::UnexpectedTokenError.new(
            "Unexpected " + @tok.type.to_s,
            @tok.pos,
            @lx.str
          )
        end
      end

      private

      def consume(type)
        if @tok.type != type
          raise TypedArgs::UnexpectedTokenError.new(
            "Expected " + type.to_s + ", got " + @tok.type.to_s,
            @tok.pos,
            @lx.str
          )
        end
        @tok = @lx.next_token
      end
    end

    # ============================================================
    # IMPL
    # ============================================================
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

          key_lexer = Lexer.new(arg, body_start, key_len)
          key_ast   = KeyParser.new(key_lexer).parse

          name = Internal.resolve_name(key_ast[:name])

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

          # validate alias-expanded short key
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

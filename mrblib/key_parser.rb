module TypedArgs
  module Internal
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
            "Expected #{type}, got #{@tok.type}",
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
  end
end

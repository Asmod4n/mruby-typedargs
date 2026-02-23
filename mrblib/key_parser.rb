# key_parser.rb
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

        if key.length > 0 && key[key.length - 1,1] == "."
          raise UnexpectedTokenError.new("Expected IDENT after DOT", @tok.pos, @lx.str)
        end

        i = 0
        while i + 1 < key.length
          if key[i,1] == "." && key[i + 1,1] == "."
            raise UnexpectedTokenError.new("Unexpected DOT", @tok.pos, @lx.str)
          end
          i += 1
        end

        if key.index(".") && @tok.type == :PLUS
          raise InvalidSuffixPositionError.new("Suffix must be at end of key", @tok.pos, @lx.str)
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
          raise InvalidSuffixPositionError.new("Suffix must be at end of key", @tok.pos, @lx.str)
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
          raise InvalidKeyStartError.new("Invalid key start", @tok.pos, @lx.str)
        end

        first = expect(:IDENT).value
        buf   = first

        while @tok.type == :DOT
          consume(:DOT)
          if @tok.type != :IDENT
            raise UnexpectedTokenError.new("Expected IDENT, got " + @tok.type.to_s, @tok.pos, @lx.str)
          end
          part = expect(:IDENT).value
          buf = buf + "." + part
        end

        buf
      end

      def parse_ident_list
        list = []
        if @tok.type != :IDENT
          raise InvalidFieldListError.new("Expected IDENT", @tok.pos, @lx.str)
        end
        list.push(expect(:IDENT).value)
        while @tok.type == :COMMA
          consume(:COMMA)
          if @tok.type != :IDENT
            raise InvalidFieldListError.new("Expected IDENT", @tok.pos, @lx.str)
          end
          list.push(expect(:IDENT).value)
        end
        list
      end

      def expect(type)
        if @tok.type != type
          raise UnexpectedTokenError.new("Expected #{type}, got #{@tok.type}", @tok.pos, @lx.str)
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

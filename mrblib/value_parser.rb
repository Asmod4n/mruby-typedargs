module TypedArgs
  module Internal
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
            "Arity mismatch: expected #{expected}, got #{vals.size}",
            @tok.pos,
            @lx.str
          )
        end
        vals
      end

      def parse_scalar
        if @tok.type == :EOF
          raise TypedArgs::UnexpectedTokenError.new(
            "Unexpected EOF",
            @tok.pos,
            @lx.str
          )
        end

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
          case v
          when "true"  then true
          when "false" then false
          when "nil"   then nil
          else
            v
          end
        else
          buf = ""
          while @tok.type != :COMMA && @tok.type != :EOF
            buf << @tok.value.to_s
            @tok = @lx.next_token
          end
          buf
        end
      end

      private

      def consume(type)
        if @tok.type != type
          raise TypedArgs::UnexpectedTokenError.new(
            "Expected #{type}, got #{@tok.type}",
            @tok.pos,
            @lx.str
          )
        end
        @tok = @lx.next_token
      end
    end
  end
end

module TypedArgs
  module Internal
    class Lexer
      attr_reader :str

      def initialize(str, start_pos, bytesize, parsing_key = false)
        @str   = str
        @i     = start_pos
        @start = start_pos
        @end   = start_pos + bytesize
        @n     = str.bytesize
        @end   = @n if @end > @n
        @parsing_key = !!parsing_key
      end

      def parsing_key?
        @parsing_key
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
          return ident_token if parsing_key?

          if Internal.digit?(c) || (c == CHAR_DASH && peek_digit?)
            return number_token
          end

          if Internal.alpha?(c) || c == CHAR_UNDERS || c >= 0x80
            j = @i
            all_ident = true
            while j < @end
              cc = @str.getbyte(j)
              break if cc <= 32 || cc == CHAR_COMMA
              unless ident_continue?(cc)
                all_ident = false
                break
              end
              j += 1
            end
            return all_ident ? ident_token : raw_value_token
          end

          raw_value_token
        end
      end

      def raw_value_token
        start = @i
        buf = ""
        while @i < @end
          c = @str.getbyte(@i)
          break if c <= 32 || c == CHAR_COMMA
          buf += @str[@i,1]
          @i += 1
        end

        if buf.bytesize > 0
          all_dashes = true
          buf.bytes.each do |b|
            all_dashes = false if b != CHAR_DASH
          end
          raise TypedArgs::InvalidCharacterError.new("Illegal number", start, @str) if all_dashes
        end

        Token.new(:STRING, buf, start)
      end

      private

      def peek_digit?
        return false if (@i + 1) >= @end
        Internal.digit?(@str.getbyte(@i + 1))
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
            buf += @str[@i,1]
            @i += 1
          end
        end
        raise TypedArgs::UnterminatedStringError.new("Unterminated string", start, @str)
      end

      def ident_start?(c)
        Internal.alpha?(c) || c == CHAR_UNDERS || c >= 0x80
      end

      def ident_continue?(c)
        Internal.alpha?(c) ||
        Internal.digit?(c) ||
        c == CHAR_UNDERS || c == CHAR_DASH || c == CHAR_DOT ||
        c >= 0x80
      end

      def ident_token
        start = @i
        buf = ""
        c = @str.getbyte(@i)
        unless ident_start?(c)
          if Internal.digit?(c)
            raise TypedArgs::InvalidKeyStartError.new("Invalid key start", @i, @str)
          else
            raise TypedArgs::InvalidCharacterError.new("Illegal character in key", @i, @str)
          end
        end
        buf += @str[@i,1]
        @i += 1
        while @i < @end
          c = @str.getbyte(@i)
          break unless ident_continue?(c)
          buf += @str[@i,1]
          @i += 1
        end
        Token.new(:IDENT, buf, start)
      end

      def number_token
        start = @i
        buf = ""
        dot = false
        digits = 0

        if @str.getbyte(@i) == CHAR_DASH
          buf += "-"
          @i += 1
        end

        while @i < @end
          c = @str.getbyte(@i)
          if Internal.digit?(c)
            buf += @str[@i,1]
            @i += 1
            digits += 1
          elsif c == CHAR_DOT
            raise TypedArgs::InvalidNumberError.new("Invalid number format", start, @str) if dot
            dot = true
            buf += "."
            @i += 1
          else
            break
          end
        end

        raise TypedArgs::InvalidCharacterError.new("Illegal number", start, @str) if digits == 0

        Token.new(dot ? :NUMBER : :NUMBER, dot ? buf.to_f : buf.to_i, start)
      end
    end
  end
end

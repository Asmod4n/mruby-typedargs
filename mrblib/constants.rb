module TypedArgs
  module Internal
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
        while i < n && str[i,1] == "-"
          i += 1
        end
        str[i, n - i]
      end

      def resolve_name(raw)
        mapped = @alias_map[raw]
        mapped ? strip_leading_dashes(mapped) : strip_leading_dashes(raw)
      end
    end
  end
end

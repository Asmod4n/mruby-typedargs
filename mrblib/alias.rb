module TypedArgs
  module Internal
    @alias_map = {}

    class << self
      def register_alias(short, long)
        @alias_map[short] = long
      end

      def resolve_name(raw)
        mapped = @alias_map[raw]
        mapped ? strip_leading_dashes(mapped) : strip_leading_dashes(raw)
      end

      private
      def strip_leading_dashes(str)
        i = 0
        n = str.bytesize
        while i < n && str[i,1] == "-"
          i += 1
        end
        str[i, n - i]
      end
    end
  end
end

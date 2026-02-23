# script_check.rb (optimized)
module TypedArgs
  module Internal
    module ScriptCheck
      LATIN_RANGES = [
        ["\u00C0", "\u024F"]
      ]
      GREEK_RANGES = [
        ["\u0370", "\u03FF"]
      ]
      CYRILLIC_RANGES = [
        ["\u0400", "\u04FF"]
      ]

      def self.in_ranges?(ch, ranges)
        j = 0
        while j < ranges.length
          start_ch, end_ch = ranges[j]
          return true if ch >= start_ch && ch <= end_ch
          j += 1
        end
        false
      end

      def self.char_bucket(ch)
        return :latin    if (ch >= "A" && ch <= "Z") || (ch >= "a" && ch <= "z") || in_ranges?(ch, LATIN_RANGES)
        return :greek    if in_ranges?(ch, GREEK_RANGES)
        return :cyrillic if in_ranges?(ch, CYRILLIC_RANGES)
        :other
      end

      def self.validate_key(str)
        seen = nil
        i = 0
        n = str.length
        while i < n
          ch = str[i,1]
          # skip punctuation
          if ch == "." || ch == "+" || ch == ":" || ch == ","
            i += 1
            next
          end
          # underscore and digits ignored for bucket
          if ch == "_" || (ch >= "0" && ch <= "9")
            i += 1
            next
          end

          bucket = char_bucket(ch)
          if bucket != :other
            if seen && seen != bucket
              raise InvalidCharacterError.new("Invalid or mixed-script key", i, str)
            end
            seen ||= bucket
          end
          i += 1
        end
        true
      end
    end
  end
end

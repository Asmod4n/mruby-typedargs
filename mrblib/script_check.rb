module TypedArgs
  module Internal
    def self.script_bucket(cp)
      if cp <= 0x7F
        return SCRIPT_ASCII if (cp >= 0x41 && cp <= 0x5A) || (cp >= 0x61 && cp <= 0x7A)
        return SCRIPT_OTHER
      end

      return SCRIPT_LATIN     if (0x00C0 <= cp && cp <= 0x024F)
      return SCRIPT_GREEK     if (0x0370 <= cp && cp <= 0x03FF)
      return SCRIPT_CYRILLIC  if (0x0400 <= cp && cp <= 0x04FF)

      SCRIPT_OTHER
    end

    def self.valid_key_script?(str)
      seen = nil
      i = 0
      n = str.bytesize

      while i < n
        b = str.getbyte(i)
        return false unless printable_byte?(b)

        cp, ni = utf8_next(str, i)
        return false if cp.nil?

        bucket = script_bucket(cp)
        if bucket != SCRIPT_OTHER
          return false if seen && seen != bucket
          seen ||= bucket
        end

        i = ni
      end

      true
    end
  end
end

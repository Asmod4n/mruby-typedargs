module TypedArgs
  module Internal
    class Token
      attr_accessor :type, :value, :pos
      def initialize(type, value, pos)
        @type  = type
        @value = value
        @pos   = pos
      end
    end
  end
end

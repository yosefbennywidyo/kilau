module Kilau
  module DB
    # Positional SQL parameters with their types, one call per parameter:
    # Binds.new.text(title).int(created_at). Each kind lives in an array of
    # its own type, with @kinds recording the order, rather than in one mixed
    # Array. A mixed Array is Array[untyped] under Spinel (docs/CATALOG.md
    # K-005), so every value would be boxed and tested at run time. Typed
    # arrays keep the binds on Spinel's typed paths. The builder also refuses
    # nil for a NOT NULL column and a NUL byte in text before SQLite sees
    # them. (It started as the workaround for K-015, an Integer in a mixed
    # binds array read back as a String, which matz/spinel#6027 fixed.)
    class Binds
      NULL = 0
      INT = 1
      FLOAT = 2
      TEXT = 3

      attr_reader :size

      def initialize
        @kinds = []
        @ints = []
        @floats = []
        @texts = []
        @size = 0
      end

      def int(value)
        raise Error, "nil given to int; use int_or_nil for a nullable column" if value.nil?
        push(INT, value, 0.0, "")
      end

      def float(value)
        raise Error, "nil given to float; use float_or_nil for a nullable column" if value.nil?
        push(FLOAT, 0, value, "")
      end

      # A NUL byte would truncate the text in C, so it is refused.
      def text(value)
        raise Error, "nil given to text; use text_or_nil for a nullable column" if value.nil?
        raise Error, "a text bind cannot contain a NUL byte" if value.include?("\0")
        push(TEXT, 0, 0.0, value)
      end

      def null = push(NULL, 0, 0.0, "")
      def int_or_nil(value) = value.nil? ? null : int(value)
      def float_or_nil(value) = value.nil? ? null : float(value)
      def text_or_nil(value) = value.nil? ? null : text(value)

      def kind(i) = @kinds[i]
      def int_at(i) = @ints[i]
      def float_at(i) = @floats[i]
      def text_at(i) = @texts[i]

      private

      def push(kind, int_value, float_value, text_value)
        @kinds << kind
        @ints << int_value
        @floats << float_value
        @texts << text_value
        @size += 1
        self
      end
    end
  end
end

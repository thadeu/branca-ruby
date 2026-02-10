# frozen_string_literal: true

module Branca
  # Bitcoin-style Base62 encoder/decoder compatible with the JavaScript
  # `base-x` library (https://github.com/cryptocoinjs/base-x).
  #
  # Leading \x00 bytes in the input map 1:1 to leading '0' characters
  # in the encoded output, and vice-versa on decode.
  module Base62
    ALPHABET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
    BASE = ALPHABET.length

    ALPHABET_MAP = ALPHABET.each_char.with_index.to_h.freeze

    class << self
      def encode(data)
        data = data.b
        return '' if data.empty?

        leading_zeros = count_leading_bytes(data, 0x00)

        int_val = bytes_to_integer(data, leading_zeros)

        encoded = integer_to_base62(int_val)

        (ALPHABET[0] * leading_zeros) + encoded
      end

      def decode(string)
        return ''.b if string.empty?

        leading_zeros = count_leading_chars(string, ALPHABET[0])

        int_val = base62_to_integer(string, leading_zeros)

        bytes = integer_to_bytes(int_val)

        ("\x00".b * leading_zeros) + bytes
      end

      private

      def count_leading_bytes(data, byte)
        count = 0
        data.each_byte { |b| b == byte ? (count += 1) : break }
        count
      end

      def count_leading_chars(string, char)
        count = 0
        string.each_char { |c| c == char ? (count += 1) : break }
        count
      end

      def bytes_to_integer(data, skip)
        int_val = 0
        data.bytes.drop(skip).each { |b| int_val = int_val * 256 + b }
        int_val
      end

      def integer_to_base62(int_val)
        return '' if int_val.zero?

        result = ''.b
        while int_val.positive?
          int_val, remainder = int_val.divmod(BASE)
          result << ALPHABET[remainder]
        end
        result.reverse
      end

      def base62_to_integer(string, skip)
        int_val = 0
        string[skip..].each_char do |c|
          digit = ALPHABET_MAP[c]
          raise ArgumentError, "invalid base62 character: #{c.inspect}" unless digit

          int_val = int_val * BASE + digit
        end
        int_val
      end

      def integer_to_bytes(int_val)
        return ''.b if int_val.zero?

        bytes = []
        while int_val.positive?
          bytes.unshift(int_val & 0xFF)
          int_val >>= 8
        end
        bytes.pack('C*')
      end
    end
  end
end

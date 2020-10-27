# frozen_string_literal: true

require 'rbnacl'
require 'base_x'

require 'branca/version'
require 'branca/exceptions'
require 'branca/decoder'

module Branca
  VERSION = 0xBA

  class << self
    attr_writer :secret_key, :ttl

    def encode(message, timestamp = Time.now.utc)
      nonce = RbNaCl::Random.random_bytes(cipher.nonce_bytes)

      header = [VERSION, timestamp.to_i].pack('C N') + nonce
      ciphertext = cipher.encrypt(nonce, message, header)
      raw_token = header + ciphertext

      BaseX::Base62.encode(raw_token)
    end

    def decode(token)
      header, bytes = token_explode(token)
      version, timestamp, nonce = header_explode(header)

      raise VersionError unless version == VERSION
      raise ExpiredTokenError if (timestamp + Branca.ttl) < Time.now.utc.to_i

      message = cipher.decrypt(nonce, bytes.pack('C*'), header.pack('C*'))
      Decoder.new(message, Time.at(timestamp).utc)
    end

    def ttl
      @ttl ||= ttl_default
    end

    def secret_key
      @secret_key ||= RbNaCl::Random.random_bytes(32)
    end

    def configure
      yield self if block_given?
    end

    private

    def cipher
      @cipher ||= RbNaCl::AEAD::XChaCha20Poly1305IETF.new(Branca.secret_key&.b)
    end

    def token_explode(token)
      bytes = BaseX::Base62.decode(token).unpack('C C4 C24 C*')
      header = bytes.shift(1 + 4 + 24)

      [header, bytes]
    end

    def header_explode(header)
      version = header[0]
      nonce = header[5..header.size].pack('C*')
      timestamp = header[1..4].pack('C*').unpack('N')&.first

      [version, timestamp, nonce]
    end

    def ttl_default
      @ttl_default ||= 86_400
    end
  end
end

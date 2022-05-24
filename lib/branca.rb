# frozen_string_literal: true

require 'rbnacl'
require 'base_x'

require 'branca/version'
require 'branca/exceptions'
require 'branca/decoder'

module Branca
  class << self
    VERSION = 0xBA

    attr_accessor :secret_key, :ttl

    def encode(message, timestamp = Time.now.utc, secret_key: self.secret_key)
      cipher = create_cipher(secret_key)
      nonce = RbNaCl::Random.random_bytes(cipher.nonce_bytes)

      header = [VERSION, timestamp.to_i].pack('C N') + nonce
      ciphertext = cipher.encrypt(nonce, message, header)
      raw_token = header + ciphertext

      BaseX::Base62.encode(raw_token)
    end

    def decode(token, ttl: self.ttl, secret_key: self.secret_key)
      header, bytes = token_explode(token)
      version, timestamp, nonce = header_explode(header)

      raise VersionError unless version == VERSION
      raise ExpiredTokenError if (timestamp + ttl) < Time.now.utc.to_i

      cipher = create_cipher(secret_key)
      message = cipher.decrypt(nonce, bytes.pack('C*'), header.pack('C*'))
    rescue RbNaCl::CryptoError
      raise DecodeError
    else
      Decoder.new(message, Time.at(timestamp).utc)
    end

    def ttl
      @ttl ||= ttl_default
    end

    def secret_key
      @secret_key&.b || RbNaCl::Random.random_bytes(32)
    end

    def configure
      yield self if block_given?
    end

    private

    def create_cipher(key)
      RbNaCl::AEAD::XChaCha20Poly1305IETF.new(key)
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

# frozen_string_literal: true

require 'spec_helper'

# Branca spec: base62 character set must be 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
BASE62_SPEC_ALPHABET = Regexp.new('^[0-9A-Za-z]+\z').freeze

RSpec.describe 'Branca token encoding (spec-compliant Base62)' do
  let(:secret_key) { 'supersecretkeyyoushouldnotcommit'.b }
  let(:ttl) { 3_600 }

  before do
    Branca.configure do |config|
      config.secret_key = secret_key
      config.ttl = ttl
    end
  end

  describe 'Base62 character set and Node.js compatibility' do
    it 'encodes tokens using only 0-9, A-Z, a-z' do
      token = Branca.encode('any payload')
      
      expect(token).to match(BASE62_SPEC_ALPHABET)
    end

    it 'never produces token starting with 0 (avoids "Invalid token version" in branca-js)' do
      token = Branca.encode('any payload')

      expect(token).not_to start_with('0')
    end

    it 'encodes Rails-like payload with spec alphabet only' do
      encode_params = {
        user_id: '123',
        user_ids: ['123', '456', '789'],
        logo_id: '1',
        stage: ENV.fetch('WEBPACKER_ENV', 'development'),
        extra: 'data'
      }

      token = Branca.encode(JSON.generate(encode_params))

      expect(token).to match(BASE62_SPEC_ALPHABET)
    end
  end

  describe 'round-trip with Rails-like payloads' do
    def encode_payload(payload)
      message = payload.is_a?(Hash) ? JSON.generate(payload) : payload.to_s
      Branca.encode(message)
    end

    it 'round-trips decode after encode for Rails-like payload' do
      encode_params = {
        user_id: '42',
        user_ids: ['42', '10', '20'],
        logo_id: '',
        stage: 'production',
        foo: 'bar'
      }

      token = encode_payload(encode_params)
      decoded = Branca.decode(token)
      parsed = JSON.parse(decoded.message)
      
      expect(parsed['user_id']).to eq('42')
      expect(parsed['user_ids']).to eq(%w[42 10 20])
      expect(parsed['logo_id']).to eq('')
      expect(parsed['stage']).to eq('production')
      expect(parsed['foo']).to eq('bar')
    end

    it 'round-trips for payload with empty logo_id and various stages' do
      %w[development production test].each do |stage|
        payload = {
          user_id: '1',
          user_ids: ['1'],
          logo_id: '',
          stage: stage
        }

        token = encode_payload(payload)
        decoded = Branca.decode(token)
        parsed = JSON.parse(decoded.message)

        expect(parsed['stage']).to eq(stage)
        expect(parsed['logo_id']).to eq('')
      end
    end

    it 'round-trips encode and decode for simple string' do
      message = 'legacy payload'
      token = Branca.encode(message)
      decoded = Branca.decode(token)

      expect(decoded.message).to eq(message)
    end

    it 'round-trips for a range of payload sizes' do
      (1..50).each do |n|
        payload = {
          user_id: n.to_s,
          user_ids: (1..n).map(&:to_s),
          logo_id: n.even? ? '' : n.to_s,
          stage: 'test'
        }

        token = encode_payload(payload)
        decoded = Branca.decode(token)
        parsed = JSON.parse(decoded.message)

        expect(parsed['user_id']).to eq(n.to_s)
        expect(parsed['user_ids'].size).to eq(n)
      end
    end
  end

  describe 'payload that previously produced invalid token for Node.js (branca-js)' do
    PAYLOAD_INVALID_IN_NODE = {
      user_id: '16574',
      user_ids: ['16574'],
      logo_id: 'c55953547000101',
      stage: 'production'
    }.freeze

    def encode_payload(payload)
      Branca.encode(JSON.generate(payload))
    end

    it 'never produces token starting with 0 for this exact payload' do
      token = encode_payload(PAYLOAD_INVALID_IN_NODE)

      expect(token).not_to start_with('0'),
        "Token must not start with '0' (branca-js would decode as Invalid token version). Got: #{token[0..40]}..."
    end

    it 'produces Node-safe token across multiple encodes (random nonce)' do
      50.times do
        token = encode_payload(PAYLOAD_INVALID_IN_NODE)

        expect(token).not_to start_with('0'),
          "Token must not start with '0'. Got: #{token[0..40]}..."
      end
    end

    it 'round-trips the exact payload that failed in Node' do
      token = encode_payload(PAYLOAD_INVALID_IN_NODE)
      decoded = Branca.decode(token)
      parsed = JSON.parse(decoded.message)

      expect(parsed['user_id']).to eq('16574')
      expect(parsed['user_ids']).to eq(['16574'])
      expect(parsed['logo_id']).to eq('c55953547000101')
      expect(parsed['stage']).to eq('production')
    end
  end
end

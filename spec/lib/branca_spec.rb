# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Branca do
  describe 'initializer setup' do
    let(:secret_key) { 'supersecretkeyyoushouldnotcommit' }
    let(:ttl) { 3_600 }

    before do
      Branca.configure do |config|
        config.secret_key = secret_key
        config.ttl = ttl
      end
    end

    context 'when configure' do
      it 'must be return ttl' do
        expect(Branca.ttl).to eq 3_600
      end

      it 'must be return a secret_key' do
        expect(Branca.secret_key).to eq 'supersecretkeyyoushouldnotcommit'
      end
    end

    context 'when dont pass secret_key' do
      let(:secret_key) { nil }
      let(:ttl) { nil }

      it 'must be return default ttl' do
        expect(Branca.ttl).to eq 86_400
      end

      it 'must be return a secret_key' do
        expect(Branca.secret_key).not_to be_empty
      end
    end
  end

  describe '.encode' do
    let(:secret_key) { 'supersecretkeyyoushouldnotcommit' }
    let(:ttl) { 3_600 }

    before do
      Branca.configure do |config|
        config.secret_key = secret_key
        config.ttl = ttl
      end
    end

    context 'with string' do
      let(:message) { 'with string' }

      subject { Branca.encode(message) }

      it { expect(subject). to be_a(String) }
    end

    context 'with json' do
      let(:message) { JSON.generate({ sub: '1234' }) }

      subject { Branca.encode(message) }

      it { expect(subject). to be_a(String) }
    end
  end

  describe '.encode without setup' do
    let(:secret_key) { 'supersecretkeyyoushouldnotcommit' }
    let(:ttl) { 3_600 }

    context 'with string' do
      let(:message) { 'with string' }

      subject { Branca.encode(message) }

      it { expect(subject). to be_a(String) }
    end
  end

  describe '.decode' do
    let(:secret_key) { 'supersecretkeyyoushouldnotcommit' }
    let(:ttl) { 3_600 }
    let(:timestamp) { Time.now }
    let!(:token) { Branca.encode('with string', timestamp) }

    before do
      Branca.configure do |config|
        config.secret_key = secret_key
        config.ttl = ttl
      end
    end

    it 'should be decode correctly' do
      decode = Branca.decode(token)
      expect(decode.message).to eq('with string')
    end

    context 'when token invalid' do
      let(:timestamp) { Time.now - 4_000 }

      it 'must be return ExpiredTokenError' do
        expect { Branca.decode(token) }.to raise_error(Branca::ExpiredTokenError)
      end
    end
  end
end

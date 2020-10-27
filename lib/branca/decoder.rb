# frozen_string_literal: true

module Branca
  class Decoder
    attr_reader :message, :timestamp

    def initialize(message, timestamp)
      @message = message
      @timestamp = timestamp
    end
  end
end

# frozen_string_literal: true

module Branca
  class VersionError < StandardError; end

  class DecodeError < StandardError
    def to_s
      "Can't decode token"
    end
  end

  class ExpiredTokenError < StandardError
    def to_s
      'Token is expired'
    end
  end
end

# frozen_string_literal: true

module Branca
  class Error < StandardError; end
  
  class VersionError < Error; end

  class DecodeError < Error
    def to_s
      "Can't decode token"
    end
  end

  class ExpiredTokenError < Error
    def to_s
      'Token is expired'
    end
  end
end

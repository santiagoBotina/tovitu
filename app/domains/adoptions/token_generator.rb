module Adoptions
  module TokenGenerator
    TOKEN_BYTES = 32
    REFERENCE_LENGTH = 8

    class << self
      def generate
        SecureRandom.urlsafe_base64(TOKEN_BYTES)
      end

      def reference(token)
        Digest::SHA256.hexdigest(token).first(REFERENCE_LENGTH).upcase
      end
    end
  end
end

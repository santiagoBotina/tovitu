module Locations
  module Providers
    class Base
      def reverse(latitude:, longitude:)
        raise NotImplementedError, "#{self.class} must implement #reverse"
      end
    end
  end
end

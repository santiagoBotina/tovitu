# frozen_string_literal: true

Rails.application.config.after_initialize do
  ActiveSupport.on_load(:active_storage_blob) do
    before_create :set_prefixed_key

    private

    def set_prefixed_key
      return if metadata.blank? || metadata["path_prefix"].blank?

      self.key = "#{metadata['path_prefix']}/#{self.class.generate_unique_secure_token}"
    end
  end
end

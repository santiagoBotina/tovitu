module Shelters
  class UpdateProfile < ApplicationService
    IMAGE_ATTACHMENTS = %w[logo cover_image profile_picture].freeze

    def initialize(shelter:, user:, params:)
      @shelter = shelter
      @user = user
      @params = params
    end

    def call
      return Result.failure(I18n.t("errors.update_profile.not_admin")) unless @user.shelter_admin?
      return Result.failure(I18n.t("errors.update_profile.wrong_shelter")) unless @user.shelter_id == @shelter.id

      text_params = @params.except(*IMAGE_ATTACHMENTS)

      ActiveRecord::Base.transaction do
        @shelter.update!(text_params)

        IMAGE_ATTACHMENTS.each do |attachment_name|
          file = @params[attachment_name.to_sym]
          next unless file

          attach_with_key(attachment_name, file)
        end
      end

      Result.success(@shelter)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end

    private

    def attach_with_key(attachment_name, file)
      key = case attachment_name
      when "logo"          then StorageKeyGenerator.shelter_logo(@shelter.name)
      when "cover_image"   then StorageKeyGenerator.shelter_cover(@shelter.name)
      when "profile_picture" then StorageKeyGenerator.shelter_profile(@shelter.name)
      end

      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.respond_to?(:original_filename) ? file.original_filename : "image",
        content_type: Marcel::MimeType.for(file),
        key: key
      )

      @shelter.send(attachment_name).attach(blob)
    end
  end
end

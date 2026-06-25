module Pets
  class PhotoManager
    ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
    MAX_FILE_SIZE = 10.megabytes
    MAX_PHOTOS    = 10

    class << self
      def attach(pet:, file:)
        return Result.failure(I18n.t("pets.errors.photos.invalid_type")) unless valid_content_type?(file)
        return Result.failure(I18n.t("pets.errors.photos.too_large"))    unless valid_file_size?(file)
        return Result.failure(I18n.t("pets.errors.photos.max_count"))   if pet.photos.count >= MAX_PHOTOS

        ActiveRecord::Base.transaction do
          key = StorageKeyGenerator.pet_photo(pet.shelter.name, pet.name)
          blob = ActiveStorage::Blob.create_and_upload!(
            io: file,
            filename: file.respond_to?(:original_filename) ? file.original_filename : File.basename(file),
            content_type: Marcel::MimeType.for(file),
            key: key
          )
          pet.photos.attach(blob)
          pet.update!(photo_order: pet.photo_order + [ blob.id ])
        end

        Result.success(pet)
      rescue ActiveRecord::RecordInvalid => e
        Result.failure(e.record.errors.full_messages)
      end

      def detach(pet:, blob_id:)
        attachment = pet.photos.find_by(blob_id: blob_id)
        return Result.failure(I18n.t("pets.errors.photos.not_found")) unless attachment

        blob_id_int = blob_id.to_i

        ActiveRecord::Base.transaction do
          attachment.purge_later
          pet.update!(photo_order: pet.photo_order.reject { |id| id == blob_id_int })
        end

        Result.success(pet)
      end

      def reorder(pet:, ordered_blob_ids:)
        ordered = ordered_blob_ids.map(&:to_i)
        existing = pet.photos.pluck(:blob_id)

        return Result.failure(I18n.t("pets.errors.photos.invalid_order")) unless ordered.sort == existing.sort

        pet.update!(photo_order: ordered)
        Result.success(pet)
      end

      def primary(pet:)
        blob_id = pet.photo_order.first
        blob_id ||= pet.photos.first&.blob_id
        return nil unless blob_id

        pet.photos.find_by(blob_id: blob_id)
      end

      private

      def valid_content_type?(file)
        ALLOWED_CONTENT_TYPES.include?(Marcel::MimeType.for(file))
      end

      def valid_file_size?(file)
        file.size <= MAX_FILE_SIZE
      end
    end
  end
end

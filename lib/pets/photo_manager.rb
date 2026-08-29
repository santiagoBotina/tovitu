module Pets
  # Manages a pet's photo set: attach (single, batch, or by URL), detach,
  # reorder, set primary, and move. All operations are scoped to the passed pet
  # (there is no cross-association surface). Primary is derived from
  # `photo_order` — the first entry — so deleting the primary naturally falls
  # back to the next photo (or to `photos.first` / a placeholder when none).
  class PhotoManager
    ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
    MAX_FILE_SIZE = 10.megabytes
    MAX_PHOTOS    = 10

    class << self
      def attach(pet:, file:)
        attach_many(pet: pet, files: [ file ])
      end

      # Attaches multiple files. Each file is validated independently (type,
      # size) and the count limit is enforced across the whole batch; valid
      # files still attach when some are rejected, so one bad file never
      # blocks the rest.
      def attach_many(pet:, files:)
        files = Array(files).compact
        return Result.failure(I18n.t("pets.errors.photos.no_files")) if files.empty?

        valid_files, per_file_errors = partition_valid(files)
        return Result.failure(per_file_errors) if valid_files.empty?

        remaining = MAX_PHOTOS - pet.photos.count

        if valid_files.length > remaining
          per_file_errors << I18n.t("pets.errors.photos.max_count")
          valid_files = valid_files.first(remaining)
        end

        blobs_attached = []
        ActiveRecord::Base.transaction do
          valid_files.each do |file|
            blob = create_blob(pet, file)
            pet.photos.attach(blob)
            blobs_attached << blob.id
          end
          pet.update!(photo_order: pet.photo_order + blobs_attached) if blobs_attached.any?
        end

        # Warm the canonical variants in the background so the first page view
        # doesn't pay on-demand generation. Best-effort: the on-demand path in
        # PetPresenter remains as a fallback if the job hasn't run yet.
        blobs_attached.each { |blob_id| Pets::GeneratePhotoVariantsJob.perform_later(blob_id) }

        result = Result.success(pet)
        return result if per_file_errors.empty?

        Result.new(success: true, data: pet, errors: per_file_errors)
      rescue ActiveRecord::RecordInvalid => e
        Result.failure(e.record.errors.full_messages)
      end

      # Fetches an image from a URL, validates its content type and size, then
      # attaches it. Rejects non-image responses and unreachable URLs with a
      # clear, friendly error before anything is associated.
      def attach_by_url(pet:, url:)
        return Result.failure(I18n.t("pets.errors.photos.url_invalid")) if url.blank?

        response = HTTParty.get(url, timeout: 15, follow_redirects: true)
        unless response.success?
          return Result.failure(I18n.t("pets.errors.photos.url_unreachable"))
        end

        content_type = response.headers["content-type"].to_s.split(";").first.to_s.strip
        unless ALLOWED_CONTENT_TYPES.include?(content_type)
          return Result.failure(I18n.t("pets.errors.photos.invalid_type"))
        end

        body = response.body
        return Result.failure(I18n.t("pets.errors.photos.too_large")) if body.bytesize > MAX_FILE_SIZE
        return Result.failure(I18n.t("pets.errors.photos.max_count")) if pet.photos.count >= MAX_PHOTOS

        filename = File.basename(URI.parse(url).path.presence || "image").presence || "image"
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(body),
          filename: filename,
          content_type: content_type,
          key: storage_key(pet)
        )

        ActiveRecord::Base.transaction do
          pet.photos.attach(blob)
          pet.update!(photo_order: pet.photo_order + [ blob.id ])
        end

        Pets::GeneratePhotoVariantsJob.perform_later(blob.id)

        Result.success(pet)
      rescue URI::InvalidURIError, HTTParty::Error, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Timeout::Error, Net::OpenTimeout
        Result.failure(I18n.t("pets.errors.photos.url_unreachable"))
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

      # Marks a photo as primary by moving it to the front of photo_order.
      def set_primary(pet:, blob_id:)
        return Result.failure(I18n.t("pets.errors.photos.not_found")) unless pet.photos.exists?(blob_id: blob_id)

        order = pet.photo_order.present? ? pet.photo_order.map(&:to_i) : pet.photos.pluck(:blob_id)
        order.delete(blob_id.to_i)
        order.unshift(blob_id.to_i)
        pet.update!(photo_order: order)
        Result.success(pet)
      end

      # Moves a photo one slot up or down in the ordering (direction: :up/:down).
      def move(pet:, blob_id:, direction:)
        order = pet.photo_order.present? ? pet.photo_order.map(&:to_i) : pet.photos.pluck(:blob_id)
        index = order.index(blob_id.to_i)
        return Result.failure(I18n.t("pets.errors.photos.not_found")) unless index

        target = direction.to_sym == :up ? index - 1 : index + 1
        return Result.failure(I18n.t("pets.errors.photos.invalid_order")) if target.negative? || target >= order.length

        order[index], order[target] = order[target], order[index]
        pet.update!(photo_order: order)
        Result.success(pet)
      end

      def primary(pet:)
        blob_id = pet.photo_order.first
        blob_id ||= pet.photos.first&.blob_id
        return nil unless blob_id

        pet.photos.find_by(blob_id: blob_id)
      end

      private

      def partition_valid(files)
        valid = []
        errors = []
        files.each do |file|
          if !valid_content_type?(file)
            errors << I18n.t("pets.errors.photos.invalid_type")
          elsif !valid_file_size?(file)
            errors << I18n.t("pets.errors.photos.too_large")
          else
            valid << file
          end
        end
        [ valid, errors ]
      end

      def create_blob(pet, file)
        ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.respond_to?(:original_filename) ? file.original_filename : "photo",
          content_type: Marcel::MimeType.for(file),
          key: storage_key(pet)
        )
      end

      def storage_key(pet)
        owner_name = (pet.shelter || pet.publisher)&.name.presence || "pet"
        StorageKeyGenerator.pet_photo(owner_name, pet.name)
      end

      def valid_content_type?(file)
        ALLOWED_CONTENT_TYPES.include?(Marcel::MimeType.for(file))
      end

      def valid_file_size?(file)
        file.size <= MAX_FILE_SIZE
      end
    end
  end
end

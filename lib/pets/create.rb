module Pets
  class Create < ApplicationService
    ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
    MAX_FILE_SIZE = 10.megabytes

    def initialize(shelter:, params:, photos: [])
      @shelter = shelter
      @params  = params
      @photos  = Array(photos)
    end

    def call
      return Result.failure(I18n.t("pets.errors.no_photos")) if @photos.empty?

      @photos.each do |photo|
        return Result.failure(I18n.t("pets.errors.photos.invalid_type")) unless valid_content_type?(photo)
        return Result.failure(I18n.t("pets.errors.photos.too_large"))    unless valid_file_size?(photo)
      end

      pet = @shelter.pets.new(@params)

      ActiveRecord::Base.transaction do
        pet.save!
        @photos.each { |photo| pet.photos.attach(photo) }
        pet.update!(photo_order: pet.photos.map(&:blob_id))
      end

      Result.success(pet)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
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

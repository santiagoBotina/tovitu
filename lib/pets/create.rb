module Pets
  class Create < ApplicationService
    def initialize(shelter:, params:, photos: [])
      @shelter = shelter
      @params  = params
      @photos  = Array(photos)
    end

    def call
      return Result.failure(I18n.t("pets.errors.no_photos")) if @photos.empty?

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
  end
end

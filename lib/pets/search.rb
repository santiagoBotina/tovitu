module Pets
  class Search < ApplicationQuery
    DEFAULT_PAGE_SIZE = 24

    def initialize(params: {})
      @page               = [ (params[:page] || 1).to_i, 1 ].max
      @per_page           = (params[:per_page] || DEFAULT_PAGE_SIZE).to_i
      @species            = params[:species]
      @breed              = params[:breed]
      @age_category       = params[:age_category]
      @size               = params[:size]
      @sex                = params[:sex]
      @city               = params[:city]
      @state              = params[:state]
      @good_with_children = params[:good_with_children]
      @good_with_dogs     = params[:good_with_dogs]
      @good_with_cats     = params[:good_with_cats]
      @query              = params[:query]
      @shelter_id         = params[:shelter_id]
      @status             = params[:status]
      @publisher          = params[:publisher]
    end

    def call
      scope = Pet.undiscarded

      scope = @status.present? ? scope.where(status: @status) : scope.available

      scope = scope.where(species: @species)                   if @species.present?
      scope = scope.where(breed: @breed)                       if @breed.present?
      scope = scope.where(age_category: @age_category)         if @age_category.present?
      scope = scope.where(size: @size)                         if @size.present?
      scope = scope.where(sex: @sex)                           if @sex.present?

      scope = scope.where(good_with_children: cast_boolean(@good_with_children)) if @good_with_children.present?
      scope = scope.where(good_with_dogs:   cast_boolean(@good_with_dogs))       if @good_with_dogs.present?
      scope = scope.where(good_with_cats:   cast_boolean(@good_with_cats))       if @good_with_cats.present?

      if @publisher == "shelter"
        scope = scope.shelter_listed
      elsif @publisher == "individual"
        scope = scope.individual_listed
      end

      if @city.present?
        scope = scope.left_joins(:shelter).where("shelters.city ILIKE ?", "%#{sanitize_like(@city)}%")
      end

      if @state.present?
        scope = scope.left_joins(:shelter).where(shelters: { state: @state.upcase })
      end

      scope = scope.where(shelter_id: @shelter_id) if @shelter_id.present?

      if @query.present?
        like_q = "%#{sanitize_like(@query)}%"
        scope = scope.where(
          "name ILIKE :q OR breed ILIKE :q OR description ILIKE :q OR requirements ILIKE :q",
          q: like_q
        )
      end

      scope = scope.order(created_at: :desc)
      scope = scope.includes(:shelter, photos_attachments: :blob)

      offset = (@page - 1) * @per_page
      scope.offset(offset).limit(@per_page)
    end

    private

    def cast_boolean(value)
      ActiveRecord::Type::Boolean.new.cast(value)
    end

    def sanitize_like(str)
      str.to_s.gsub(/[%_\\]/, '\\\\\0')
    end
  end
end

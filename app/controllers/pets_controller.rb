class PetsController < ApplicationController
  before_action :set_pet, only: [ :show ]

  def index
    if params[:intent].present?
      render_intent_search
    else
      @pets = Pets::Search.call(params: index_params)
      @pets = @pets.includes(:shelter, photos_attachments: :blob)
      @presented_pets = @pets.map { |pet| PetPresenter.new(pet) }
    end
    skip_authorization

    respond_to do |format|
      format.html
    end
  end

  def show
    authorize @pet
    @pet = PetPresenter.new(@pet)
  end

  private

  def set_pet
    @pet = Pet.undiscarded.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to pets_path, alert: t("pets.not_found")
  end

  # Natural-language search: extract intent from the phrase, rank the
  # structured-filter-constrained candidate set by relevance, then paginate the
  # ordered ids. Degrades to plain browse with a friendly banner when the
  # phrase is unreadable or the AI service fails (never a 500).
  def render_intent_search
    intent_result = Ai::ExtractSearchIntent.call(phrase: params[:intent], locale: I18n.locale)

    if intent_result.failure?
      render_invalid_intent
      return
    end

    @intent = intent_result.data
    if @intent["valid"] == false
      render_invalid_intent
      return
    end

    ranked = Pets::NaturalSearch.call(
      pets: Pets::Search.constraint_scope(params: index_params),
      intent: @intent,
      locale: I18n.locale
    )

    if ranked.failure?
      render_invalid_intent
      return
    end

    page = (params[:page] || 1).to_i
    page = 1 if page < 1
    per_page = (params[:per_page] || Pets::Search::DEFAULT_PAGE_SIZE).to_i.clamp(1, Pets::Search::MAX_PER_PAGE)
    ids = ranked.data["ordered_ids"]
    page_ids = ids[((page - 1) * per_page), per_page] || []

    pets_by_id = Pet.where(id: page_ids)
                    .includes(:shelter, photos_attachments: :blob)
                    .index_by(&:id)
    @pets = page_ids.filter_map { |id| pets_by_id[id] }
    @reasons = ranked.data["reasons"]
    @presented_pets = @pets.map { |pet| PetPresenter.new(pet) }
  end

  def render_invalid_intent
    @nl_error = true
    @intent = nil
    @pets = Pets::Search.call(params: index_params)
    @pets = @pets.includes(:shelter, photos_attachments: :blob)
    @presented_pets = @pets.map { |pet| PetPresenter.new(pet) }
  end

  def index_params
    params.permit(:locale, :page, :per_page, :species, :breed, :age_category, :size, :sex,
                  :city, :state, :good_with_children, :good_with_dogs, :good_with_cats,
                  :query, :shelter_id, :intent)
  end
end

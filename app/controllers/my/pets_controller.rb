module My
  class PetsController < ApplicationController
    before_action :require_authentication
    before_action :require_individual

    def index
      @pets = current_user.published_pets.undiscarded.order(created_at: :desc)
      @pending_requests_count = AdoptionRequest.pending_for_publisher(current_user).count
    end

    def show
      @pet = current_user.published_pets.undiscarded.find(params[:id])
      @incoming_requests = @pet.adoption_requests.newest_first
    end

    def new
      @pet = Pet.new
    end

    def create
      result = Pets::Publish.call(
        publisher: current_user,
        params: pet_params,
        photos: Array(params[:pet][:photos])
      )

      if result.success?
        redirect_to my_pet_path(result.data), notice: t("flash.my.pets.created")
      else
        @pet = Pet.new(pet_params)
        flash.now[:alert] = Array(result.errors).join(", ")
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @pet = current_user.published_pets.undiscarded.find(params[:id])
    end

    def update
      @pet = current_user.published_pets.undiscarded.find(params[:id])

      result = Pets::Update.call(pet: @pet, params: pet_params)

      if result.success?
        redirect_to my_pet_path(@pet), notice: t("flash.my.pets.updated")
      else
        flash.now[:alert] = Array(result.errors).join(", ")
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @pet = current_user.published_pets.undiscarded.find(params[:id])
      @pet.discard!
      redirect_to my_pets_path, notice: t("flash.my.pets.removed")
    end

    def change_status
      @pet = current_user.published_pets.undiscarded.find(params[:id])

      result = Pets::ChangeStatus.call(
        pet: @pet,
        new_status: params[:status],
        adopted_at: params[:adopted_at]
      )

      if result.success?
        redirect_to my_pet_path(@pet), notice: t("flash.my.pets.status_updated")
      else
        redirect_to my_pet_path(@pet), alert: Array(result.errors).join(", ")
      end
    end

    private

    def require_individual
      unless current_user.individual?
        redirect_to root_path, alert: t("flash.unauthorized")
      end
    end

    def pet_params
      params.require(:pet).permit(
        :name, :species, :breed, :age_category, :birth_date,
        :size, :sex, :description, :personality_traits,
        :medical_notes, :requirements, :status,
        :spayed_neutered, :vaccinated, :special_needs,
        :good_with_children, :good_with_dogs, :good_with_cats,
        :personality_spec, :adopter_tips
      )
    end
  end
end

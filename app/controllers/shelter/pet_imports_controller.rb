class Shelter::PetImportsController < ApplicationController
  before_action :require_authentication
  before_action :require_shelter
  before_action :set_pet_import, only: [ :show, :status ]

  SUPPORTED_EXTENSIONS = %w[.csv .xlsx].freeze

  def index
    @pet_imports = policy_scope(PetImport).latest.limit(20)
  end

  def new
    @pet_import = current_shelter.pet_imports.new(user: current_user)
    authorize @pet_import
  end

  def create
    file = params[:pet_import]&.dig(:file)
    unless file.present?
      @pet_import = current_shelter.pet_imports.new(user: current_user)
      authorize @pet_import
      flash.now[:alert] = t("shelter.pet_imports.errors.file_required")
      render :new, status: :unprocessable_entity and return
    end

    extension = File.extname(file.original_filename.to_s).downcase
    unless SUPPORTED_EXTENSIONS.include?(extension)
      @pet_import = current_shelter.pet_imports.new(user: current_user)
      authorize @pet_import
      flash.now[:alert] = t("shelter.pet_imports.errors.format")
      render :new, status: :unprocessable_entity and return
    end

    @pet_import = current_shelter.pet_imports.new(
      user: current_user,
      file_name: file.original_filename,
      status: "pending"
    )
    authorize @pet_import
    @pet_import.file.attach(file)

    if @pet_import.save
      PetImportJob.perform_later(@pet_import.id)
      redirect_to shelter_pet_import_path(@pet_import), notice: t("shelter.pet_imports.notices.started")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @pet_import
  end

  def status
    authorize @pet_import, :status?

    respond_to do |format|
      format.turbo_stream
      format.json { render json: pet_import_status_json(@pet_import) }
    end
  end

  def template
    csv = Pets::ImportTemplate.call
    send_data csv, type: "text/csv", disposition: "attachment", filename: "tovitu-pets-template.csv"
  end

  private

  def set_pet_import
    @pet_import = current_shelter.pet_imports.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to shelter_pet_imports_path, alert: t("pets.not_found")
  end

  def pet_import_status_json(pet_import)
    return { status: "none" } unless pet_import

    {
      status: pet_import.status,
      imported_count: pet_import.imported_count,
      duplicate_count: pet_import.duplicate_count,
      error_count: pet_import.error_count,
      total_count: pet_import.total_count,
      error: pet_import.error
    }
  end

  def require_shelter
    unless current_user.shelter_id.present?
      redirect_to root_path, alert: t("flash.unauthorized")
    end
  end

  def current_shelter
    @current_shelter ||= current_user.shelter
  end
end

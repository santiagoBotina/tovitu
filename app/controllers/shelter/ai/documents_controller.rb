class Shelter::Ai::DocumentsController < ApplicationController
  before_action :require_authentication
  before_action :require_shelter_staff

  def index
    @documents = current_shelter.ai_documents.order(created_at: :desc)
    authorize @documents
  end

  def new
    @document = current_shelter.ai_documents.build
    authorize @document
  end

  def create
    @document = current_shelter.ai_documents.build(document_params)
    authorize @document

    if @document.source_type == "pdf" && @document.file.attached?
      @document.content = I18n.t("ai.document.pdf_placeholder")
    end

    if @document.save
      Ai::ProcessDocumentJob.perform_later(@document.id)
      redirect_to shelter_ai_documents_path,
                  notice: I18n.t("flash.ai.document.uploaded")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @document = current_shelter.ai_documents.find(params[:id])
    authorize @document
    @document.destroy!
    redirect_to shelter_ai_documents_path,
                notice: I18n.t("flash.ai.document.destroyed")
  end

  private

  def document_params
    params.require(:ai_document).permit(:title, :content, :source_type, :file)
  end

  def current_shelter
    @current_shelter ||= current_user.shelter
  end

  def require_shelter_staff
    unless current_user.shelter_id.present?
      redirect_to root_path, alert: I18n.t("flash.unauthorized")
    end
  end
end

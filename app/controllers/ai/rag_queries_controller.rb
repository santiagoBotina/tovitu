module Ai
  class RagQueriesController < ApplicationController
    def create
      skip_authorization
      if params[:shelter_id]
        handle_shelter_query
      elsif params[:adoption_application_id]
        handle_application_query
      else
        render json: { error: "Invalid query target" }, status: :unprocessable_entity
      end
    end

    private

    def handle_shelter_query
      @shelter = Shelter.undiscarded.find(params[:shelter_id])

      question = params[:question]
      return render json: { error: I18n.t("ai.rag.question_required") }, status: :unprocessable_entity if question.blank?

      cache_key = "rag_faq/#{@shelter.id}/#{Digest::MD5.hexdigest(question)}"
      answer = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        perform_rag_query(
          question: question,
          scope: Ai::DocumentChunk.joins(:ai_document)
                                  .where(ai_documents: { shelter_id: @shelter.id }),
          prompt_name: "rag_faq"
        )
      end

      render json: { answer: answer }
    end

    def handle_application_query
      @application = AdoptionApplication.find_by!(token: params[:adoption_application_id])

      question = params[:question]
      return render json: { error: I18n.t("ai.rag.question_required") }, status: :unprocessable_entity if question.blank?

      shelter_scope = Ai::DocumentChunk.joins(:ai_document)
                                       .where(ai_documents: { shelter_id: @application.shelter_id })

      timeline_summary = @application.adoption_timeline_events.order(:created_at).pluck(:event_type, :created_at)
      notes_summary = @application.adoption_notes.order(created_at: :desc).limit(5).pluck(:content)

      answer = perform_rag_query(
        question: question,
        scope: shelter_scope,
        prompt_name: "rag_application_qa",
        extra_variables: {
          application_status: @application.status,
          application_submitted_at: I18n.l(@application.created_at.to_date),
          pet_name: @application.pet.name,
          pet_species: @application.pet.species,
          pet_breed: @application.pet.breed.presence || "Mixed",
          application_timeline: timeline_summary.map { |e, t| "#{e} (#{I18n.l(t.to_date)})" }.join(", ").presence || I18n.t("ai.rag.no_events"),
          application_notes: notes_summary.join("\n").presence || I18n.t("ai.rag.no_notes")
        }
      )

      render json: { answer: answer }
    end

    def perform_rag_query(question:, scope:, prompt_name:, extra_variables: {})
      embedding = Ai::Rag::EmbeddingService.call(question)
      chunks = Ai::Rag::VectorSearch.call(embedding: embedding, scope: scope, limit: 5)
      Ai::Rag::QueryEngine.call(
        question: question,
        context_chunks: chunks,
        system_prompt_name: prompt_name,
        extra_variables: extra_variables
      )
    end
  end
end

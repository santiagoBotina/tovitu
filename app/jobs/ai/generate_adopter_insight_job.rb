module Ai
  class GenerateAdopterInsightJob < ApplicationJob
    queue_as :default

    def perform(request_id: nil, adopter_id: nil)
      result =
        if request_id.present?
          request = AdoptionRequest.find(request_id)
          Ai::Adopter::Analysis.call(adopter: request.adopter, request: request)
        else
          adopter = User.find(adopter_id)
          Ai::Adopter::Analysis.call(adopter: adopter)
        end

      raise result.errors.join(", ") unless result.success?
    end
  end
end

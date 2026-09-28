module Adoptions
  class EvaluateRequestJob < ApplicationJob
    queue_as :default

    def perform(request_id:)
      request = AdoptionRequest.find(request_id)
      result = Adoptions::EvaluateRequest.call(request: request)

      raise result.errors.join(", ") unless result.success?
    end
  end
end

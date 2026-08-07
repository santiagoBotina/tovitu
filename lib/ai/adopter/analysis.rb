module Ai
  module Adopter
    # Orchestrates insight generation for one adoption request.
    #
    #  1. Compiles the PII-free signal payload for the adopter.
    #  2. Refreshes the cached Adopter Insight Profile when stale
    #     (fingerprint change or TTL expiry), deduped via row lock.
    #  3. Generates the per-request Pet-Fit Summary.
    #
    # Never blocks the request flow: failures are returned as a failed Result
    # and the caller (job) decides how to retry.
    class Analysis < ApplicationService
      def initialize(adopter:, request: nil)
        @adopter = adopter
        @request = request
        super()
      end

      def call
        signals = SignalCollector.call(adopter: adopter)

        insight_result = ensure_insight!(signals)
        return insight_result unless insight_result.success?

        pet_fit_result = request ? ensure_pet_fit!(signals, insight_result.data) : Result.success(nil)
        return pet_fit_result unless pet_fit_result.success?

        Result.success(
          insight: insight_result.data,
          pet_fit: pet_fit_result.data,
          signals: signals
        )
      rescue Ai::ProviderError => e
        Result.failure(e.message)
      rescue JSON::ParserError => e
        Result.failure("Failed to parse AI response: #{e.message}")
      end

      private

      attr_reader :adopter, :request

      def ensure_insight!(signals)
        record = AdopterInsight.create_or_find_by!(adopter: adopter)

        # The row lock serializes concurrent jobs for the same adopter: the
        # second caller blocks until the first commits, then re-checks freshness
        # and no-ops. This is the dedupe contract (AC3).
        outcome = record.with_lock do
          if record.fresh_for?(signals[:fingerprint])
            { status: :fresh, record: record }
          else
            generated = InsightAnalyzer.call(adopter: adopter, signals: signals)
            if generated.success?
              record.update!(
                data: generated.data,
                signal_fingerprint: signals[:fingerprint],
                version: prompt_version("adopter_insight"),
                generated_at: Time.current
              )
              { status: :generated, record: record.reload }
            else
              { status: :failed, errors: generated.errors }
            end
          end
        end

        return Result.failure(outcome[:errors].join(", ")) if outcome[:status] == :failed

        Result.success(outcome[:record])
      end

      def ensure_pet_fit!(signals, insight)
        fingerprint = pet_fit_fingerprint(signals, insight)
        return Result.success(request.pet_fit_data) if request.pet_fit_fingerprint == fingerprint

        result = PetFitAnalyzer.call(request: request, signals: signals, insight: insight.data)
        return result unless result.success?

        request.update!(
          pet_fit_data: result.data,
          pet_fit_generated_at: Time.current,
          pet_fit_version: prompt_version("pet_fit_summary"),
          pet_fit_fingerprint: fingerprint,
          pet_fit_signal_fingerprint: signals[:fingerprint]
        )

        Result.success(result.data)
      end

      def pet_fit_fingerprint(signals, insight)
        Digest::SHA256.hexdigest(
          [
            signals[:fingerprint],
            insight.signal_fingerprint,
            request.pet_id,
            prompt_version("pet_fit_summary")
          ].join("|")
        )
      end

      def prompt_version(name)
        path = Rails.root.join("config/prompts/#{name}.yml")
        YAML.load_file(path)["version"] || 1
      end
    end
  end
end

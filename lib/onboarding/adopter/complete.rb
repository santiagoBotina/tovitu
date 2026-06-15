module Onboarding
  module Adopter
    class Complete < ApplicationService
      TOTAL_QUESTIONS = 8

      def initialize(user:, skip: false)
        @user = user
        @skip = skip
      end

      def call
        profile = @user.adopter_profile

        if @skip && profile.nil?
          profile = @user.build_adopter_profile
          profile.save!
        end

        return Result.failure([ I18n.t("errors.onboarding.no_profile") ]) unless profile

        unless @skip
          unanswered = (1..TOTAL_QUESTIONS).select do |qnum|
            field = Onboarding::Adopter::SaveResponse::QUESTION_FIELDS[qnum]
            value = profile[field]
            value.blank? || (value.is_a?(Array) && value.empty?)
          end

          if unanswered.any?
            return Result.failure(
              [ I18n.t("errors.onboarding.incomplete", questions: unanswered.join(", ")) ]
            )
          end
        end

        ActiveRecord::Base.transaction do
          profile.update!(onboarding_step: TOTAL_QUESTIONS)
          @user.update!(
            onboarding_step: TOTAL_QUESTIONS,
            onboarding_completed_at: Time.current
          )
        end

        Result.success(
          user_id: @user.id,
          redirect_path: "/pets"
        )
      rescue ActiveRecord::RecordInvalid => e
        Result.failure(e.record.errors.full_messages)
      end
    end
  end
end

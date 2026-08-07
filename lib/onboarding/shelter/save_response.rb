module Onboarding
  module Shelter
    class SaveResponse < ApplicationService
      QUESTION_FIELDS = {
        1 => :organization_type,
        2 => :pet_count_range,
        3 => :adoption_involvement,
        4 => :approval_priorities,
        5 => :communication_channels,
        6 => :biggest_challenges,
        7 => :approval_philosophy
      }.freeze

      def initialize(user:, question_number:, answer:)
        @user = user
        @question_number = question_number.to_i
        @answer = answer
      end

      def call
        field = QUESTION_FIELDS[@question_number]
        return Result.failure([ I18n.t("errors.onboarding.invalid_question") ]) unless field

        question = Onboarding::Shelter::QuestionsData.find(@question_number)
        if question[:type] == "text" && question[:max_length] && @answer.to_s.length > question[:max_length]
          return Result.failure([ I18n.t("errors.onboarding.answer_too_long", max_length: question[:max_length]) ])
        end

        profile = @user.shelter_profile || @user.build_shelter_profile
        profile[field] = coerce_answer(field, @answer)
        profile.onboarding_step = [ @question_number, profile.onboarding_step.to_i ].max
        @user.onboarding_step = profile.onboarding_step

        ActiveRecord::Base.transaction do
          profile.save!
          @user.save!
        end

        Result.success(
          question_number: @question_number,
          field: field,
          onboarding_step: profile.onboarding_step,
          total_questions: 7,
          complete: profile.onboarding_step >= 7
        )
      rescue ActiveRecord::RecordInvalid => e
        Result.failure(e.record.errors.full_messages)
      end

      private

      def coerce_answer(field, answer)
        column_type = ShelterProfile.columns_hash[field.to_s]&.type

        case column_type
        when :jsonb
          Array(answer).map(&:to_s)
        else
          answer.to_s.presence
        end
      end
    end
  end
end

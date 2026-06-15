module Adoptions
  class AddNote < ApplicationService
    def initialize(application:, user:, content:, pinned: false)
      @application = application
      @user        = user
      @content     = content
      @pinned      = pinned
    end

    def call
      return Result.failure(I18n.t("adoptions.errors.note_content_required")) if @content.blank?

      note = @application.adoption_notes.new(
        user:   @user,
        content: @content.strip,
        pinned:  @pinned
      )

      if note.save
        Result.success(note)
      else
        Result.failure(note.errors.full_messages)
      end
    end
  end
end

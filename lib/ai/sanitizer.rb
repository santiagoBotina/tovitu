module Ai
  # Strips identifying patterns from free text before it reaches a prompt.
  # Enforces AI business rule 10 (no PII in prompts) for user-authored fields.
  module Sanitizer
    EMAIL_PATTERN = /[\w.+-]+@[\w-]+(?:\.[\w-]+)+/
    # Loose candidate matcher; the block requires a phone-like digit count so
    # date-like strings (e.g. "2024-08-06", 8 digits) are preserved.
    PHONE_CANDIDATE_PATTERN = /(?:\+?\d[\d\s().-]{7,}\d)/
    PHONE_MIN_DIGITS = 9

    module_function

    def text(value)
      return nil if value.blank?

      value.to_s
           .gsub(EMAIL_PATTERN, "[email]")
           .gsub(PHONE_CANDIDATE_PATTERN) { |match| phone_like?(match) ? "[phone]" : match }
           .strip
    end

    def truncated(value, limit: 500)
      text = text(value)
      return nil if text.blank?

      text.length > limit ? "#{text[0, limit]}…" : text
    end

    def phone_like?(candidate)
      candidate.gsub(/\D/, "").length >= PHONE_MIN_DIGITS
    end
  end
end

module Pets
  # Validates and normalizes shelter/publisher-authored pet recommendations
  # before they are stored and rendered on the public pet profile.
  #
  # The recommendation is treated as untrusted user input: it is sanitized to
  # plain text (no HTML/JS can survive) and checked against a profanity
  # blocklist so the app never displays malicious or abusive content. It is
  # rendered with ERB auto-escaping as a second line of defense.
  module Recommendation
    MAX_LENGTH = 600

    # Blocks and stripped constructs, in a deliberate order. A recommendation
    # is never expected to contain markup, so tags are simply removed.
    SCRIPT_BLOCK_TAG_RE = %r{<(script|style|iframe|object|embed|link|meta)[^>]*>.*?</\1\s*>}im
    TAG_RE             = /<[^>]*>/
    COMMENT_RE         = /<!--.*?-->/m
    EVENT_HANDLER_RE   = /\bon\w+\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]*)/i
    DANGEROUS_URL_RE   = /(?:javascript|vbscript|data)\s*:/i
    MULTISPACE_RE      = /[ \t]+/

    module_function

    # Returns the plain-text, length-bounded, stripped recommendation, or nil
    # when the input is blank/whitespace-only.
    def sanitize(value)
      return nil if value.blank?

      text = CGI.unescapeHTML(value.to_s)
      text = text.gsub(SCRIPT_BLOCK_TAG_RE, " ")
      text = text.gsub(COMMENT_RE, " ")
      text = text.gsub(TAG_RE, " ")
      text = text.gsub(EVENT_HANDLER_RE, " ")
      text = text.gsub(DANGEROUS_URL_RE, " ")
      text = text.gsub(MULTISPACE_RE, " ")

      # Normalize line breaks introduced by tag removal, then re-strip HTML so
      # entity-decoded payloads (e.g. "&lt;b&gt;") cannot smuggle markup back in.
      text = text.gsub(/[ \t]*\n[ \t]*/, "\n").gsub(TAG_RE, " ").strip
      text = nil if text.blank?
      text&.slice(0, MAX_LENGTH)
    end

    # True when the (already sanitized) text contains blocklisted profanity.
    def inappropriate?(value)
      return false if value.blank?
      words = normalize(value).split(/\W+/)
      words.any? { |word| BLOCKLIST.include?(word) }
    end

    def appropriate?(value)
      !inappropriate?(value)
    end

    # Normalizes leetspeak so "h0rny" and "h@te" match their plain words.
    def normalize(value)
      value.to_s
           .downcase
           .tr("0@4", "oaa")
           .tr("3", "e")
           .tr("1!|", "iil")
           .tr("5$", "ss")
           .tr("7", "t")
           .tr("8", "b")
           .tr("9", "g")
    end
    private_class_method :normalize

    # Curated blocklist (English + Spanish). Deliberately conservative to
    # avoid over-blocking; word-boundary matched against normalized words.
    BLOCKLIST = %w[
      asshole asshat bastard bitch bitching bollocks bullshit cocksucker cunt
      dickhead dipshit douchebag fuck fucker fucking fuckshit fucktard motherfucker
      nigger shit shitting shitty slut sonofabitch twat wanker whore
      cabron cabrón carajo chinga chingada cojones concha culo estupida estúpida
      gilipollas hijueputa hija de puta hijo de puta joder mamada mamon mamón
      mierda pendejo perra pinche pito porno puta puto
    ].freeze
  end
end

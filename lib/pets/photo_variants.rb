module Pets
  # Canonical photo variant definitions for pet photos.
  #
  # Every consumer (presenters, views, background jobs) builds variants through
  # this class so the generated variant keys always match — an upload-time
  # pre-generation job and an on-demand request must produce the *same* stored
  # variant or the pre-generation is wasted.
  #
  # All variants are re-encoded as WebP at quality 80. Active Storage's default
  # output format is PNG (lossless), which bloats JPEG uploads; WebP q80 is
  # roughly a third of the size with no visible quality loss for pet photos.
  class PhotoVariants
    VARIANTS = {
      thumb:  { resize_to_limit: [ 150, 150 ], format: :webp, saver: { quality: 80 } },
      medium: { resize_to_limit: [ 400, 400 ], format: :webp, saver: { quality: 80 } },
      large:  { resize_to_limit: [ 1200, 1200 ], format: :webp, saver: { quality: 80 } }
    }.freeze

    # Display aspect ratios for the containers each variant is shown in, used
    # as width/height hints on <img> tags to prevent layout shift.
    DISPLAY_DIMENSIONS = {
      thumb:  [ 150, 150 ],
      medium: [ 400, 300 ],
      large:  [ 1200, 750 ]
    }.freeze

    def self.for(photo, variant)
      photo.variant(**VARIANTS.fetch(variant.to_sym))
    end

    def self.keys
      VARIANTS.keys
    end

    def self.display_dimensions(variant)
      DISPLAY_DIMENSIONS.fetch(variant.to_sym)
    end
  end
end

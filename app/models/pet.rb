class Pet < ApplicationRecord
  belongs_to :shelter, touch: true

  delegate :ai_features_enabled?, to: :shelter, allow_nil: true
  has_many_attached :photos
  has_many :adoption_applications, dependent: :restrict_with_error
  has_many :adoption_requests, dependent: :restrict_with_error

  SPECIES = %w[dog cat other].freeze
  AGE_CATEGORIES = %w[baby young adult senior].freeze
  SIZES = %w[small medium large giant].freeze
  SEXES = %w[male female unknown].freeze
  STATUSES = %w[available on_hold adopted not_available removed].freeze

  enum :species, SPECIES.index_by(&:itself).transform_values(&:to_sym), prefix: true
  enum :age_category, AGE_CATEGORIES.index_by(&:itself).transform_values(&:to_sym), prefix: true
  enum :size, SIZES.index_by(&:itself).transform_values(&:to_sym), prefix: true, default: nil
  enum :sex, SEXES.index_by(&:itself).transform_values(&:to_sym), prefix: true
  enum :status, STATUSES.index_by(&:itself).transform_values(&:to_sym), prefix: true

  validates :name, presence: true
  validates :species, presence: true, inclusion: { in: SPECIES }
  validates :age_category, presence: true, inclusion: { in: AGE_CATEGORIES }
  validates :sex, presence: true, inclusion: { in: SEXES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :size, inclusion: { in: SIZES, allow_blank: true }
  validates :breed, length: { maximum: 100 }, allow_blank: true

  after_update :invalidate_life_preview_if_needed

  validate :birth_date_matches_age_category, if: -> { birth_date.present? && age_category.present? }
  validate :photo_count_within_limit
  validate :adopted_at_required_when_adopted, if: -> { status == "adopted" }

  scope :available,       -> { where(status: "available").undiscarded }
  scope :on_hold,         -> { where(status: "on_hold").undiscarded }
  scope :adopted,         -> { where(status: "adopted").undiscarded }
  scope :not_available,   -> { where(status: "not_available").undiscarded }
  scope :removed,         -> { where(status: "removed") }
  scope :discarded,       -> { where.not(discarded_at: nil) }
  scope :undiscarded,     -> { where(discarded_at: nil) }
  scope :visible,         -> { undiscarded.where.not(status: %w[removed not_available]) }
  scope :searchable,      -> { available }
  scope :recently_added,  -> { available.order(created_at: :desc) }
  scope :by_shelter,      ->(id) { where(shelter_id: id) }

  LIFE_PREVIEW_INVALIDATING_ATTRIBUTES = %w[
    description personality_traits medical_notes requirements
    species breed age_category size
    spayed_neutered vaccinated special_needs
    good_with_children good_with_dogs good_with_cats
    personality_spec adopter_tips
  ].freeze

  def life_preview_stale?
    life_preview_data.blank? ||
      life_preview_version.zero? ||
      life_preview_version != self.class.current_life_preview_version
  end

  def mark_life_preview_stale!
    update_columns(life_preview_version: 0)
  end

  def clear_life_preview!
    update_columns(
      life_preview_data: nil,
      life_preview_generated_at: nil,
      life_preview_version: 0
    )
  end

  def self.current_life_preview_version
    path = Rails.root.join("config/prompts/life_preview.yml")
    YAML.load_file(path)["version"] || 2
  rescue Errno::ENOENT
    2
  end

  def discard!
    update!(discarded_at: Time.current, status: "removed")
  end

  def undiscard!
    update!(discarded_at: nil)
  end

  def discarded?
    discarded_at.present?
  end

  def undiscarded?
    discarded_at.blank?
  end

  def primary_photo
    return photos.first unless photo_order.present? && photo_order.any?
    ordered_photos.first
  end

  def ordered_photos
    return photos.order(created_at: :asc) unless photo_order.present? && photo_order.any?
    ordered_blob_ids = photo_order.map(&:to_s)
    photos.sort_by { |p| ordered_blob_ids.index(p.blob_id.to_s) || Float::INFINITY }
  end

  private

  def invalidate_life_preview_if_needed
    return unless (LIFE_PREVIEW_INVALIDATING_ATTRIBUTES & saved_changes.keys).any?
    clear_life_preview!
  end

  def birth_date_matches_age_category
    age = compute_age
    expected = age_to_category(age)
    return if expected == age_category

    errors.add(:birth_date,
               I18n.t("pets.errors.birth_date_mismatch",
                      category: I18n.t("pets.age_categories.#{expected}")))
  end

  def compute_age
    now = Time.current.utc.to_date
    bd  = birth_date
    now.year - bd.year - ((now.month > bd.month || (now.month == bd.month && now.day >= bd.day)) ? 0 : 1)
  end

  def age_to_category(age)
    case age
    when 0...1 then "baby"
    when 1...3 then "young"
    when 3...8 then "adult"
    else "senior"
    end
  end

  def photo_count_within_limit
    return unless photos.count > 10
    errors.add(:photos, I18n.t("pets.errors.too_many_photos"))
  end

  def adopted_at_required_when_adopted
    return if adopted_at.present?
    errors.add(:adopted_at, I18n.t("pets.errors.adopted_at_required"))
  end
end

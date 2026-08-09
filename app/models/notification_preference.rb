class NotificationPreference < ApplicationRecord
  belongs_to :user

  validates :in_app, inclusion: { in: [ true, false ] }
  validates :email, inclusion: { in: [ true, false ] }
  validates :whatsapp, inclusion: { in: [ true, false ] }
  validates :whatsapp_phone,
            presence: true,
            if: -> { whatsapp? && whatsapp_verified_at.present? }

  scope :whatsapp_opted_in, -> { where(whatsapp: true).where.not(whatsapp_verified_at: nil) }
  scope :whatsapp_verified, -> { where.not(whatsapp_verified_at: nil) }

  def channel_enabled?(channel)
    public_send(channel)
  end

  # A channel is enabled for a kind only when the global toggle is on AND
  # (there is no per-kind override, or the override explicitly enables it).
  # Global OFF always wins: a stale per-kind override can never resurrect a
  # channel the user has disabled globally.
  def kind_enabled?(kind, channel)
    return false unless channel_enabled?(channel)

    overrides = per_kind_overrides&.dig(kind.to_s)
    return overrides[channel.to_s] if overrides&.key?(channel.to_s)

    true
  end

  # Per-kind override state independent of the global toggle — used to render
  # the per-kind checkboxes. Defaults to enabled when there is no override, so
  # an untouched kind renders checked under a globally-enabled channel.
  def per_kind_enabled?(kind, channel)
    overrides = per_kind_overrides&.dig(kind.to_s)
    return overrides[channel.to_s] if overrides&.key?(channel.to_s)

    true
  end

  # Coerce form values ("1"/"0"/"true"/"false") from per-kind checkboxes into
  # real booleans so the stored JSON stays clean and predictable.
  def per_kind_overrides=(value)
    normalized = value.to_h.transform_values do |channels|
      channels.to_h.transform_values { |v| ActiveModel::Type::Boolean.new.cast(v) }
    end
    super(normalized)
  end

  # Kinds the preferences UI should offer per-kind control for: only kinds that
  # can actually be triggered today. Deferred/removed kinds would be dead
  # controls.
  def self.ui_kinds
    %w[
      request_submitted request_in_validation request_accepted
      request_declined request_withdrawn welcome
    ]
  end

  def self.defaults_for(user)
    find_or_create_by!(user: user) do |p|
      p.in_app = true
      p.email = true
      p.whatsapp = false
    end
  end
end

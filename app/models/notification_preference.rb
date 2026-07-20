class NotificationPreference < ApplicationRecord
  belongs_to :user

  validates :in_app, inclusion: { in: [true, false] }
  validates :email, inclusion: { in: [true, false] }
  validates :whatsapp, inclusion: { in: [true, false] }
  validates :whatsapp_phone,
            presence: true,
            if: -> { whatsapp? && whatsapp_verified_at.present? }

  scope :whatsapp_opted_in, -> { where(whatsapp: true).where.not(whatsapp_verified_at: nil) }
  scope :whatsapp_verified, -> { where.not(whatsapp_verified_at: nil) }

  def channel_enabled?(channel)
    public_send(channel)
  end

  def kind_enabled?(kind, channel)
    overrides = per_kind_overrides&.dig(kind.to_s)
    return overrides[channel.to_s] if overrides&.key?(channel.to_s)

    channel_enabled?(channel)
  end

  def self.defaults_for(user)
    find_or_create_by!(user: user) do |p|
      p.in_app = true
      p.email = true
      p.whatsapp = false
    end
  end
end

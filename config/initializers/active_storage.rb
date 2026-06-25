# frozen_string_literal: true

Rails.application.config.after_initialize do
  ActiveStorage::Engine.config.active_storage.tap do |config|
    config.variant_processor = :vips
  end
end

Rails.application.reloader.to_prepare do
  ActiveSupport::Notifications.subscribe("preview.active_storage") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    event.payload[:blob].record&.touch
  end
end

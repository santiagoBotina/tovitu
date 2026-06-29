RSpec.configure do |config|
  config.before(:each, type: :request) do
    Rails.application.routes.default_url_options = { locale: :en }
  end
end

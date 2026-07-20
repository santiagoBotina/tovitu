RSpec.configure do |config|
  config.before(:each) do |example|
    Rails.application.routes.default_url_options = { locale: :en }
  end

  config.include Rails.application.routes.url_helpers, type: :request
end

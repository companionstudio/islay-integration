RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.mock_with :rspec
  config.fixture_path = "#{Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
  config.order = "random"
end

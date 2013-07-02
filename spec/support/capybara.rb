# Explicitly assigning the app is required in order to see the exceptions and
# stack-trace.
Capybara.app = Rack::ShowExceptions.new(IslayIntegration::Application)
Capybara.javascript_driver = :poltergeist
Capybara.default_driver = :poltergeist

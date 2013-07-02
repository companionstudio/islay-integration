ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/mocks'
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

# Fake a current user so as to make the user tracking magic just work
Thread.current[:current_user] = User.first || FactoryGirl.create(:user)

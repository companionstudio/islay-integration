ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rspec'
require 'ffaker'
require 'capybara/rails'
require 'capybara/poltergeist'

Capybara.javascript_driver = :poltergeist
Capybara.default_driver = :poltergeist

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
end

# Fake a current user so as to make the user tracking magic just work
Thread.current[:current_user] = User.first || FactoryGirl.create(:user)

# A helper class for generating sets of data from factories.
class SpecData
  include FactoryGirl::Syntax::Methods
  @@definitions = {}

  def self.define(name, &blk)
    @@definitions[name.to_sym] = blk
  end

  def self.run(*names)
    names.each do |name|
      raise "Definition '#{name}' not found" unless @@definitions.has_key?(name)
      new(@@definitions[name]).run
    end
  end

  def initialize(blk)
    @blk = blk
  end

  def run
    instance_eval(&@blk)
  end
end


source 'https://rubygems.org'

ruby "1.9.3"

gem 'spooky_core', :git => "git@github.com:spookandpuff/spooky-core.git"

gem 'islay',      :path => '../islay'
gem 'islay_shop', :path => '../islay-shop'
gem 'islay_blog', :path => '../islay-blog'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'uglifier', '>= 1.0.3'
end

group :test, :development do
  gem 'rspec-rails',        "2.13.2"
  gem 'factory_girl_rails', "4.2.1"
  gem "ffaker",             "1.16.1"
end

group :test do
  gem "capybara",      "2.1.0"
  gem "poltergeist",   "1.3.0"
  gem 'vcr',           "2.5.0"
  gem 'webmock',       "1.12.3"
end

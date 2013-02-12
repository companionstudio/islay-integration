source 'https://rubygems.org'

gem 'pg'

gem 'spooky_core', :git => "git@github.com:spookandpuff/spooky-core.git"

gem 'islay',      :path => '../islay'
gem 'islay_shop', :path => '../islay-shop'
gem 'islay_blog', :path => '../islay-blog'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'uglifier', '>= 1.0.3'
end

group :test, :development do
  gem 'rspec-rails',   "~> 2.12.2"
end

group :test do
  gem "machinist",     "~> 2.0"
  gem "ffaker",        "~> 1.15.0"
  gem "capybara",      "~> 1.1.2"
  gem "poltergeist",   "~> 1.0.2"
end

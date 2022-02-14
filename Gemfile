source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.1'

gem 'rails', '~> 6.1.3'
gem 'rexml', '~> 3.2.5'
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.6'
gem 'sass-rails', '>= 6'
gem 'webpacker', '~> 5.0'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.7'
gem 'bootsnap', '>= 1.4.4', require: false
gem 'bootstrap', '~> 4.5'
gem 'devise', '~> 4.7', '>= 4.7.1'
gem 'devise-bootstrapped', github: 'excid3/devise-bootstrapped', branch: 'bootstrap4'
gem 'devise-async'
gem 'sendgrid-ruby'
gem 'font-awesome-sass', '~> 5.13'
gem 'friendly_id', '~> 5.3'
gem 'image_processing'
gem 'madmin'
gem 'mini_magick', '~> 4.10', '>= 4.10.1'
gem 'redis', '~> 4.2', '>= 4.2.2'
gem 'sidekiq', '~> 6.4'
gem 'anycable-rails', '~> 1.0'
gem 'aws-healthcheck'
gem 'aws-sdk-s3'
gem 'aws-sdk-cloudwatch'
gem 'foreman'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'dotenv-rails', require: 'dotenv/rails-now'
end

group :development do
  gem 'web-console', '>= 4.1.0'
  gem 'rack-mini-profiler', '~> 2.0'
  gem 'listen', '~> 3.3'
  gem 'letter_opener_web'
end

group :test do
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

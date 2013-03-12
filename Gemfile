source 'https://rubygems.org'

gem 'rails', '3.2.12'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# commented out because don't need it for this project
#gem 'sqlite3'

# added for Heroku
group :development do
  gem 'mysql2'
end

group :production do
  gem 'therubyracer-heroku', '0.8.1.pre3'
  gem 'pg'
end

gem 'json', '~>1.7.7'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'

# for Stripe https://stripe.com/docs/libraries
gem 'stripe', :git => 'https://github.com/stripe/stripe-ruby'

# for https://github.com/mkdynamic/omniauth-facebook && https://github.com/intridea/omniauth
# don't use version 1.4.1 due to bug mentioned here: http://stackoverflow.com/questions/10737200/how-to-rescue-omniauthstrategiesoauth2callbackerror
gem 'omniauth-facebook', '1.4.0'

group :development, :test do
  gem "rspec-rails", ">= 2.8.1"
end

# for push notifications. See pubnub.com
gem "pubnub", "~> 3.3.0.2"

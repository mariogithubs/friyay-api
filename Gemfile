ruby '2.3.5'
source 'https://rubygems.org'

gem 'dotenv-rails'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.10'
gem 'rails-api', '~> 0.4.x'

# Use postgresql as the database for Active Record
gem 'pg'
gem 'schema_plus_pg_indexes' # Allows for indexes with expressions like lower(tenant_name)

# To create our multi-tenancy
gem 'apartment'
gem 'apartment-sidekiq'

# Use Devise for Authentication
gem 'devise'
# Use Doorkeeper to protect API using OAuth2
gem 'doorkeeper'
# Use JWT to generate JSON token
gem 'jwt'
# Use Rack CORS to allow applications to make cross domain AJAX calls
gem 'rack-cors', require: 'rack/cors'

# Ancestry for Topic/subtopic relationships
gem 'ancestry'

# Pagination
gem 'kaminari'

# Gems for object connections
gem 'acts_as_follower'
gem 'acts_as_commentable_with_threading'
# If you plan to use the acts_as_votable plugin with your comment system be sure to uncomment
# the line acts_as_votable in lib/comment.rb

# Gem for Votes and Likes
gem 'acts_as_votable', '~> 0.10.0'

# Gems for Roles & Permissions
gem 'cancancan', '~> 1.10'
gem 'rolify', :git => 'git://github.com/groupstance/rolify.git'

# For History logs, Undo Delete, etc...
gem 'paper_trail', '~> 7.1.0'

# For automatic archiving when trying to delete
# gem "paranoia", "~> 2.2"

# Use Certified gem to bundle SSL certificates
gem 'certified'

# Use Pusher for realtime messages
gem 'pusher'

# API Gems
gem 'active_model_serializers', '0.10.0.rc3'
gem 'fast_jsonapi'

# Search gems
gem 'sunspot_rails', '>= 2.2.4'

# CSV Importing
gem 'smarter_csv'

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.12'

# Content Manipulation Gems (Markdown, HTML, Text)
gem 'redcarpet'

# File upload and manipulation
gem 'carrierwave'
gem 'fog-aws'
gem 'carrierwave_direct'
gem 'zencoder', '~> 2.0'
gem 'sidekiq'
gem 'sidekiq-failures'
gem 'mini_magick'
gem 'carrierwave_backgrounder'
gem 'aws-sdk', '~> 2'

gem 'sinatra'
gem 'haml'
gem 'rails-observers'
gem 'ledermann-rails-settings', require: 'rails-settings'
gem 'unread'
gem 'link_thumbnailer'

# Schedule automatic tasks
gem 'whenever', require: false

# Single Signon - SSO
gem 'ruby-saml', '~> 1.0.0'

gem 'slack-ruby-bot'
# gem 'celluloid-io'
gem 'httparty'

# Application Monitoring
# We also use a datadog agent on the server for server monitoring
gem 'rollbar'

# EMAIL GEMS
gem 'sendgrid-ruby'
gem 'griddler'
gem 'griddler-sendgrid'
gem 'slack-ruby-client', '~> 0.13'

# Utility gems used in rake tasks and console
gem 'hirb'

# Use rack mini profiler for performance report
gem 'rack-mini-profiler', require: false
gem 'flamegraph'
gem 'stackprof' # ruby 2.1+ only
gem 'memory_profiler'

# Ordering gems
gem 'acts_as_list'

# Stripe payments
gem 'stripe'

#pdf generation
gem 'prawn-rails'

#get country city list
gem 'city-state'

gem 'active_record_query_trace'

gem 'instrumental_agent'

#for generating string diffs 
gem 'differ'

group :development, :test, :staging do
  # Use FactoryGirl for fixtures
  gem 'factory_girl_rails', '~> 4.8.x'
  gem 'ffaker'
end

group :development do
  # Capistrano to deploy our app to our servers
  gem 'capistrano-rails', '~> 1.1.x'
  gem 'capistrano-rvm'
  gem 'capistrano-passenger'
  gem 'capistrano-sidekiq'

  gem 'rubocop', require: false
  gem 'rubocop-rspec'
  gem 'scss_lint', require: false
  gem 'rubycritic', require: false

  # Continuously guarding system against broken rules
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'guard-rubocop'
  gem 'guard-rubycritic'

  gem 'pry'

  # Annotate model schema
  gem 'annotate'

  # Don't output assets logs
  gem 'quiet_assets'

  # Use Foreman to start server
  gem 'foreman'
  # Use Overcommit to handle commit hooks
  gem 'overcommit'
  # Use Bullet to detect N+1 queries
  gem 'bullet'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 2.0'

  # Use RSpec as test framework
  gem 'rspec-rails', '~> 3.0'
  # Use Shoulda matchers
  gem 'shoulda-matchers'
  # RSpec formatter
  gem 'fuubar'

  # Clean test database
  gem 'database_cleaner', github: 'DatabaseCleaner/database_cleaner'

  gem 'sunspot_solr'

  # Use Puma as the app server
  gem 'thin'
  gem 'webmock'

  gem 'scout_apm'
end

group :test do
  gem 'test_after_commit'
  # Test Stripe payment
  gem 'stripe-ruby-mock', '~> 2.5.1', :require => 'stripe_mock'
end

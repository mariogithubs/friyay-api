Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_deliveries = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on pages load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  config.default_url_options = { host: 'tiphive.dev' }
  config.action_mailer.default_url_options = { host: 'tiphive.dev' }

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = { address: 'localhost', port: 1025 }

  # ActionMailer::Base.smtp_settings = {
  #   user_name: ENV['SENDGRID_USERNAME'],
  #   password: ENV['SENDGRID_PASSWORD'],
  #   domain: 'localhost:3000',
  #   address: 'smtp.sendgrid.net',
  #   port: 587,
  #   authentication: :plain,
  #   enable_starttls_auto: true
  # }

  # config.logger = Logger.new(STDOUT)

  # file_logger = Logger.new(Rails.root.join("log/#{Rails.env}.log"))
  # config.logger.extend(ActiveSupport::Logger.broadcast(file_logger))

  config.after_initialize do
    Bullet.enable = false
    # Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    # Bullet.growl = true
    # Bullet.xmpp = { account:            'bullets_account@jabber.org',
    #                 password:           'bullets_password_for_jabber',
    #                 receiver:           'your_account@jabber.org',
    #                 show_online_status: true }
    Bullet.rails_logger = true
    # Bullet.honeybadger = true
    # Bullet.bugsnag = true
    # Bullet.airbrake = true
    # Bullet.rollbar = true
    # Bullet.add_footer = true
    # Bullet.stacktrace_includes = %w(your_gem your_middleware)
    # Bullet.stacktrace_excludes = %w(their_gem their_middleware)
    # Bullet.slack = { webhook_url: 'http://some.slack.url', foo: 'bar' }
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)

    # Truncating doesn't drop schemas, ensure we're clean here, app *may not* exist
    begin
      Apartment::Tenant.drop('app')
    rescue Apartment::TenantNotFound
      nil
    end
    # Create the default user for our tests
    default_user = FactoryGirl.create(:user, first_name: 'Admin')
    # Create the default tenant for our tests
    Domain.create!(name: 'app', user: default_user)
  end

  config.before(:each) do
    # Start transaction for this test
    DatabaseCleaner.start
    # Switch into the default tenant
    Apartment::Tenant.switch! 'app'
  end

  config.after(:each) do
    # Reset tentant back to `public`
    Apartment::Tenant.reset
    # Rollback transaction
    DatabaseCleaner.clean
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

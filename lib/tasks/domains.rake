namespace :domains do
  desc 'List domains'
  task list: :environment do
    require 'hirb'
    Hirb.enable

    domains = Domain.select(:id, :name, :tenant_name)

    puts Hirb::Helpers::AutoTable.render(domains)
  end

  desc 'Rename domain'
  task rename: :environment do
    require 'hirb'
    Hirb.enable

    printf 'What is the tenant_name you want to modify? '
    tenant_name = STDIN.gets.chomp

    domain = Domain.find_by(tenant_name: tenant_name)
    puts "Domain not found" if domain.blank?
    next if domain.blank?

    puts Hirb::Helpers::AutoTable.render(domain.attributes.slice('name', 'tenant_name', 'sso_enabled', 'is_public', 'join_type'))

    printf 'What is the new name?(leave blank for no change) '
    new_name = STDIN.gets.chomp

    domain.name = new_name if new_name.present?

    printf 'What is the new tenant_name?(leave blank for no change) '
    old_tenant_name = domain.tenant_name
    new_tenant_name = STDIN.gets.chomp

    if new_tenant_name.present?
      puts "WARNING: this will change the database schema name to #{new_tenant_name}"
      printf 'Continue?(yes/no) '
      contine_or_not = STDIN.gets.chomp
    end

    next if new_tenant_name.blank? && new_name.blank?

    next unless contine_or_not.try(:downcase) == 'yes'

    domain.rename({ new_name: new_name, new_tenant_name: new_tenant_name })
  end

  desc 'Remove Domain'
  task remove: :environment do
    printf 'What is the tenant_name you want to delete? '
    tenant_name = STDIN.gets.chomp

    domain = Domain.find_by(tenant_name: tenant_name)
    puts "Domain not found" if domain.blank?
    next if domain.blank?

    puts "WARNING: this will delete the database schema as well!"
    printf 'Continue?(yes/no) '
    contine_or_not = STDIN.gets.chomp

    next unless contine_or_not.try(:downcase) == 'yes'

    delete_slack_teams(domain)
    delete_domain(domain)
    drop_schema(domain)

    puts "Domain #{domain.tenant_name} deleted"
  end

  def delete_slack_teams(domain)
    domain.slack_teams.delete_all
  end

  def delete_domain(domain)
    domain.delete
  end

  def drop_schema(domain)
    sql = "DROP SCHEMA #{domain.tenant_name} CASCADE;"
    puts ActiveRecord::Base.connection.execute sql
  end
end
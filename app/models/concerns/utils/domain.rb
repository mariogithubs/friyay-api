module Utils
  # WARNING - These methods have possible serious side effects
  # Only use if you completely understand what it does
  module Domain
    extend ActiveSupport::Concern

    def rename(args)
      old_name = name.dup
      old_tenant_name = tenant_name.dup

      new_name = args[:new_name] || old_name
      new_tenant_name = args[:new_tenant_name] || old_tenant_name

      begin
        update_attribute(:tenant_name, new_tenant_name)
        update_attribute(:name, new_name)
        Rails.logger.info('Domain updated, changing database schema name...')
        if new_tenant_name.present?
          sql = "ALTER SCHEMA \"#{old_tenant_name}\" RENAME TO \"#{new_tenant_name}\";"
          Rails.logger.info(ActiveRecord::Base.connection.execute sql)
        end
        Rails.logger.info('Database Schema updated.')
      rescue => e
        Rails.logger.info('Domain could not be saved')
        Rails.logger.info(e)
      end
    end
  end
end

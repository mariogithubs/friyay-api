require 'aws-sdk'
require 'csv'

namespace :domain_permissions do
  desc 'Backup all domain permissions'
  task all_permissions: :environment do
    ActiveRecord::Base.logger.level = 1 # Avoid log in Rake task

    puts 'backing up all domain permissions'

    s3 = Aws::S3::Resource.new(region:'us-west-2')
    date = DateTime.now.utc.to_date.to_s
    dir_base = 'backup_permissions/' + date

    headers = %w(
      id
      permissible_type
      permissible_id
      created_at
      updated_at
      topic_id
      type
      access_hash
    )

    Domain.all.each do |domain|
      tenant_name = domain.tenant_name

      Apartment::Tenant.switch(tenant_name) do
        permissions = DomainPermission.all
        next if permissions.blank?

        puts "\n ---- backing up #{tenant_name} ----"
        dir = "#{dir_base}/#{tenant_name}"
        obj = s3.bucket('tiphivebackups').object("#{dir}/permissions.csv")

        file_csv = CSV.generate do |csv|
          csv << headers

          permissions.each do |domain_permission|
            print "."
            csv << domain_permission.attributes.values
          end

          puts "\n"
        end

        puts "committing csv to aws"
        obj.put body: file_csv
      end # Tenant
    end
  end

  desc 'Add group to all domain permissions'
  task add_group: :environment do
    Domain.all.each do |domain|
      tenant_name = domain.tenant_name

      Apartment::Tenant.switch(tenant_name) do
        DomainPermission.all.each do |permission|
          current_access = permission.access_hash
          new_access_items = {
            create_group:     { roles: ['member', 'power'] },
            edit_group:       {},
            destroy_group:    {}
          }

          new_access_hash = current_access.merge(new_access_items)
          permission.update_attribute(:access_hash, new_access_hash)
        end
      end
    end
  end

  desc 'Restore all domain permissions'
  task restore_permissions: :environment do
    # open file
    # parse csv
    # update_attribute

    s3 = Aws::S3::Resource.new(region:'us-west-2')

    # assume we're running same day
    date = DateTime.now.utc.to_date.to_s
    dir_base = 'backup_permissions/' + date

    Domain.all.each do |domain|
      tenant_name = domain.tenant_name

      Apartment::Tenant.switch(tenant_name) do
        next if DomainPermission.count < 1

        puts "\n ---- restoring #{tenant_name} permissions ----"
        dir = "#{dir_base}/#{tenant_name}"
        obj = s3.bucket('tiphivebackups').object("#{dir}/permissions.csv")
        next unless obj.exists?

        # read the file into a csv in memory
        csv = obj.get.body.read
        csv_rows = CSV.parse(csv)

        # assume we have a header row
        headers = csv_rows.shift

        # convert csv array of arrays to hash with headers as keys
        csv_rows = csv_rows.map { |row| Hash[headers.zip(row)] }

        csv_rows.each do |row|
          permission = DomainPermission.find_by(id: row['id'])
          next if permission.blank?

          new_access_hash = JSON.parse(row['access_hash'].gsub(/=>/, ':'))
          permission.update_attribute(:access_hash, new_access_hash)
        end

      end # Tenant
    end

  end

  desc 'Restore old default for old domains'
  task restore_old_default: :environment do

    OLD_DEFAULT_ACCESS_HASH = {
      create_topic:     { roles: ['member'] },
      edit_topic:       {},
      destroy_topic:    {},

      create_tip:       { roles: ['member'] },
      edit_tip:         {},
      destroy_tip:      {},
      like_tip:         { roles: ['member'] },
      comment_tip:      { roles: ['member'] },

      create_group:     { roles: ['member'] },
      edit_group:       {},
      destroy_group:    {}
    }

    Domain.all.each do |domain|
      Apartment::Tenant.switch(domain.tenant_name) do
        # Old default needs to be set only for those
        # that are falling back to DEFAULT_ACCESS_HASH
        if domain.domain_permission.nil?
          domain.domain_permission_attributes = {
            access_hash: OLD_DEFAULT_ACCESS_HASH
          }
          domain.save!
        end
      end
    end
  end
end

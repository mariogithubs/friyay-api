require 'fileutils'

namespace :reports do
  desc 'All root topics to individual domain CSV files'
  task all_topics: :environment do
    gather_domain_names.each do |domain_name|
      fields = 'id,title,description'
      conditions = 'WHERE ancestry IS NULL'

      ensure_path("topics")

      sql = "COPY (SELECT #{fields} FROM \"#{domain_name}\".topics #{conditions})"
      sql += " TO '#{filepath}/topics/#{domain_name}_topics.csv' CSV HEADER;"

      connection.execute sql
    end

    puts "CSV files created in #{filepath}"
  end

  desc 'All users to one CSV file'
  task all_users: :environment do
    fields = 'id,email,first_name,last_name'

    sql = "COPY (SELECT #{fields} FROM public.users) TO '#{filepath}/all_users.csv' CSV HEADER;"

    connection.execute sql

    puts "CSV files created in #{filepath}"
  end

  desc 'Daily user report'
  task daily_users: :environment do
    Rails.logger.info("***** Beginning Daily User Report ******")

    ensure_path("users")

    start_date_string = build_start_date_string
    next if start_date_string.nil?

    end_date_string = Time.now.change(hour: 15, min: 0, sec: 0).to_s(:db)

    Rails.logger.info("reporting between #{start_date_string} and #{end_date_string}")

    headers = [
      'User ID',
      'Email',
      'First Name',
      'Last Name',
      'Hive Name',
      'Joined TipHive',
      'Joined Hive'
    ]

    domain_users_query = %{
      SELECT dm.user_id, u.email, u.first_name, u.last_name, d.tenant_name AS domain, DATE(u.created_at) AS "Joined TipHive", DATE(dm.created_at) AS "Joined Domain"
      FROM domain_memberships dm
      JOIN users u
      ON u.id = dm.user_id
      JOIN domains d
      ON dm.domain_id = d.id
      WHERE dm.created_at at time zone 'UTC' at time zone 'US/Eastern' BETWEEN ('#{start_date_string}') AND ('#{end_date_string}')
      AND email NOT ILIKE '%+%'
      AND email NOT ILIKE 'mscholl87%'
      ORDER BY dm.created_at DESC
    }

    domain_users_count = connection.execute "SELECT COUNT(*) FROM (#{domain_users_query.squish}) AS domain_users_count;"
    domain_users_count = domain_users_count.values.flatten.first
    domain_users_csv_filename = "domain-users-#{Date.today.to_s(:db)}.csv"

    begin
      results = connection.execute domain_users_query

      CSV.open("#{filepath}/users/#{domain_users_csv_filename}", 'wb') do |csv|
        csv << headers

        results.values.each do |row|
          csv << row
        end
      end
      # connection.execute "COPY (#{domain_users_query.squish}) TO '#{filepath}/users/#{domain_users_csv_filename}' CSV HEADER;"
    rescue
      Rails.logger.info("***** Something went wrong with the domain_user csv save ******")

      AdminMailer.notify(
        subject: 'Daily User Report Failed',
        body: "Something went wrong with the domain_user csv save"
      ).deliver_now

      next
    end

    new_users_query = %{
      select id, email, first_name, last_name, 'NO DOMAIN' AS domain, DATE(created_at) AS "Joined TipHive", '' AS "Joined Domain"
      from users
      where users.id NOT IN (
        select user_id from domain_memberships
       )
      and email NOT LIKE '%+%'
      and created_at at time zone 'UTC' at time zone 'US/Eastern' BETWEEN ('#{start_date_string}') AND ('#{end_date_string}')
    }

    new_users_count = connection.execute "SELECT COUNT(*) FROM (#{new_users_query.squish}) AS domain_users_count;"
    new_users_count = new_users_count.values.flatten.first
    new_users_csv_filename = "new-users-#{Date.today.to_s(:db)}.csv"

    begin
      results = connection.execute new_users_query

      CSV.open("#{filepath}/users/#{new_users_csv_filename}", 'wb') do |csv|
        csv << headers

        results.values.each do |row|
          csv << row
        end
      end
      # connection.execute "COPY (#{new_users_query.squish}) TO '#{filepath}/users/#{new_users_csv_filename}' CSV HEADER;"
    rescue
      Rails.logger.info("***** Something went wrong with the new_user csv save ******")

      AdminMailer.notify(
        subject: 'Daily User Report Failed',
        body: "Something went wrong with the new_user csv save"
      ).deliver_now

      next
    end

    in_domain('tiphiveteam') do
      topic = user_stats_topic
      user = DomainMember.find_by(email: 'anthonylassiter@gmail.com')
      title = Date.today.to_s(:nice)
      body = "domain_users: #{domain_users_count} \nusers: #{new_users_count}"

      tip = Tip.create(user: user, title: title, body: body)
      tip.follow(topic)

      domain_users_csv = Document.new
      domain_users_csv.file = File.open([filepath, "users", domain_users_csv_filename].join("/"))
      domain_users_csv.save

      new_users_csv = Document.new
      new_users_csv.file = File.open([filepath, "users", new_users_csv_filename].join("/"))
      new_users_csv.save

      tip.attachments << domain_users_csv
      tip.attachments << new_users_csv

      tip.attachments.update_all(user_id: user.id)

      tip.process_attachments_as_json
    end

    Rails.logger.info("***** new_domain_users report complete ******")
  end
end

def connection
  @connection ||= ActiveRecord::Base.connection
end

def in_domain(tenant_name)
  Apartment::Tenant.switch tenant_name do
    yield
  end
end

def cd(domain_name)
  Apartment::Tenant.switch! domain_name
end

def filepath
  "#{Rails.root}/tmp/reports"
end

def ensure_path(req_path)
  FileUtils.mkdir_p([filepath, req_path].join("/"))
end

def gather_domain_names(specific_tenant_name=nil)
  domains = []

  domains << Domain.find_by(tenant_name: 'tenant') if specific_tenant_name
  return if specific_tenant_name

  domains = Domain.all
  domains << Domain.new(tenant_name: 'public')

  domains.map(&:tenant_name).sort
end

def user_stats_topic
  return Topic.with_root.last if Rails.env == 'development'

  Topic.find_by(title: 'Reports').children.find_by(title: 'User Statistics')
end

def build_start_date_string
  start_date = nil

  in_domain('tiphiveteam') do
    topic = user_stats_topic
    tip = topic.tip_followers.last

    begin
      start_date = Time.parse(tip.title).change(hour: 15)
    rescue
      Rails.logger.info("***** Last user report Title could not be changed to a date ******")
      start_date = Time.now.yesterday.change(hour: 15, min: 0, sec: 0)
    end
  end

  # Nullify start date if we've already reported
  Rails.logger.info("Start Date already reported") if start_date == Time.now.change(hour: 15, min: 0, sec: 0)
  return nil if start_date == Time.now.change(hour: 15, min: 0, sec: 0)

  start_date.to_s(:db)
end
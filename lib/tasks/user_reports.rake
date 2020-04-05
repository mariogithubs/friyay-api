namespace :user_reports do
  desc 'domain_users'
  task :domain_users => :environment do
    end_date = DateTime.now.change(hour: 15, min: 0, sec: 0)
    start_date = end_date - 10.days
    share_list = %w(madiken@tiphive.com shannice@tiphive.com)

    SQL = %{
      SELECT dm.user_id, u.email, u.first_name, u.last_name, d.tenant_name AS domain, DATE(u.created_at) AS "Joined TipHive", DATE(dm.created_at) AS "Joined Domain"
      FROM domain_memberships dm
      JOIN users u
      ON u.id = dm.user_id
      JOIN domains d
      ON dm.domain_id = d.id
      WHERE dm.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'US/Eastern' BETWEEN ('#{start_date.to_s(:db)}') AND ('#{end_date.to_s(:db)}')
      AND email NOT ILIKE '%+%'
      AND email NOT ILIKE 'mscholl87%'
      ORDER BY dm.created_at DESC;
    }

    results = ActiveRecord::Base.connection.execute SQL

    # TODO:
    # Create an HTML table for the Tip with the results
    # Do this after we convert to using HTML for tips
    # then create the tip and share with Share_list

    # tip = Tip.new(
    #   title: end_date.to_date.to_s(:nice),
    #   body:
  end
end
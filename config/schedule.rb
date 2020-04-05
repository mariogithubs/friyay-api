# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
# if @environment == 'production'
#   every :day, at: '12:00pm' do
#     rake 'email:send_daily_activity_feed'
#   end

#   every :day, at: '8:00pm' do
#     rake 'reports:daily_users'
#   end

#   # every :day, at: '10:00pm' do
#   #   rake 'email:notifications_report'
#   # end

#   # every :day, at: '4:00am' do
#   #   rake 'email:notifications_report'
#   # end
# end
# every :monday, at: '11:30am' do
#   rake 'email:send_weekly_activity_feed'
# end

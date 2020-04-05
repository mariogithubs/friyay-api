namespace :add_username do
  desc "Add username to all existing users"
  task all_users: :environment do
    i = 0
    User.find_in_batches(batch_size: 100) do |users|
      i = i + 1
      users.each do |user|
        user.add_username

        puts "UserID #{user.id} - username #{user.username}."
      end
    end
    puts "#{i} users updated."
  end
end

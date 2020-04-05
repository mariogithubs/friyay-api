namespace :confirm do
  desc "Confirm all existing users"
  task all_users: :environment do
    User.find_in_batches(batch_size: 100) do |users|
      users.each do |user|
        user.confirm
      end
    end
  end
end

# == Schema Information
#
# Table name: mentions
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  mentionable_id   :integer
#  mentionable_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Mention < ActiveRecord::Base
  belongs_to :mentionable, polymorphic: true
  belongs_to :user

  def self.add_and_remove(resource, old_mentions, new_mentions)
    add(resource, new_mentions)
    remove(resource, old_mentions - new_mentions)
  end

  def self.add(resource, mentions)
    mentions.each do |username|
      user = User.find_by('username ILIKE ?', username)

      next unless user

      resource.mentions.find_or_create_by(user_id: user.id)
    end
  end

  def self.remove(resource, mentions)
    mentions.each do |username|
      user = User.find_by('username ILIKE ?', username)
      next unless user

      mention = resource.mentions.find_by(user_id: user.id)
      mention.destroy
    end
  end
end

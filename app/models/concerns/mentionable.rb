module Mentionable
  extend ActiveSupport::Concern

  def mentioned_users
    usernames = parse_mentions(Parse::MENTION_REGEXP).flatten.uniq

    User.where('lower(username) IN (?)', usernames.map(&:downcase))
  end
end

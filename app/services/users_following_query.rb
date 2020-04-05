class UsersFollowingQuery
  def initialize(relation = User.all)
    @relation = relation
  end

  def all_domain_members
    following_all_domain_members
  end

  def all_topics
    following_all_topics
  end

  private

  def following_all_domain_members
    @relation.joins(:user_profile)
      .joins(join_settings_to_user)
      .where(settings:
        {
          target_type: 'UserProfile',
          var: 'domain_follows'
        }).where("settings.value LIKE '%follow_all_domain_members: true%'")
  end

  def following_all_topics
    @relation.joins(:user_profile)
      .joins(join_settings_to_user)
      .where(settings:
        {
          target_type: 'UserProfile',
          var: 'domain_follows'
        }).where("settings.value LIKE '%follow_all_topics: true%'")
  end

  def join_settings_to_user
    'JOIN settings ON settings.target_id = user_profiles.id'
  end
end

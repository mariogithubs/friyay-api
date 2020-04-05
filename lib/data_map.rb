module DataMap
  DATE_FIELDS = %i(current_sign_in_at last_sign_in_at created_at updated_at)
  BOOLEAN_FIELDS = %i(share_public share_following)
  NULL_FIELDS = %i(latitude longitude vote_weight vote_scope)

  class DateConverter
    def self.convert(value)
      return "'2012-01-01 12:00:00 UTC'" if value.blank?
      # Time.strptime( value.to_s, '%Y-%m-%d %H:%M:%S %z') # parses custom date format into Date instance
    end
  end

  def self.date_converter_hash
    keys = DATE_FIELDS
    hash = {}

    keys.map do |key|
      hash[key] = DateConverter
    end

    hash
  end


  # ************ SPECIAL USER ONLY METHODS ************
  def self.value_to_strings_user(key, raw_value)
    return "''" if empty_string_keys.include?(key) && raw_value.blank?
    raw_value = string_cleanup_user(raw_value) if raw_value.is_a?(String)

    raw_value.blank? ? 'NULL' : "'#{raw_value}'"
  end

  def self.string_cleanup_user(string)
    # string = ActiveRecord::Base.connection.quote(string)
    string = string.gsub("'", "\\'")
    string = ActionView::Base.full_sanitizer.sanitize(string)

    string
  end
  # ************ END USER ONLY METHODS **************

  def self.process(key, raw_value)
    # puts "processing #{key} - #{raw_value} - #{blank_or_null?(raw_value)}"
    return "'2012-01-01 12:00:00 UTC'" if DATE_FIELDS.include?(key) && blank_or_null?(raw_value)
    return "NULL" if key.to_s.ends_with?("_id") && blank_or_null?(raw_value)
    return "NULL" if key.to_s.ends_with?("_ip") && blank_or_null?(raw_value)
    return "NULL" if NULL_FIELDS.include?(key) && blank_or_null?(raw_value)
    return false if BOOLEAN_FIELDS.include?(key) && blank_or_null?(raw_value)

    return color_to_index(raw_value) if key == :background_color_index
    return "''" if empty_string_keys.include?(key) && raw_value.blank?

    value_to_strings(key, raw_value)
  end

  def self.value_to_strings(key, raw_value)
    raw_value = string_cleanup(raw_value) if raw_value.is_a?(String)

    raw_value.blank? ? 'NULL' : raw_value
  end

  def self.string_cleanup(string)
    string = ActionView::Base.full_sanitizer.sanitize(string)
    string = ActiveRecord::Base.connection.quote(string)
    # string = string.gsub("'", "\\'")

    string
  end

  def self.blank_or_null?(raw_value)
    raw_value.blank? || raw_value == 'NULL'
  end

  def self.empty_string_keys
    # Special allowance to make empty instead of NULL
    [:encrypted_password, :description]
  end

  def self.color_to_index(value)
    return 0 if value.blank?
    colors = %w(white liteorange orange purple litepurple green liteblue blue)
    colors.index(value)
  end

  def self.user_map
    {
      id: :id,
      email: :email,
      encrypted_password: :encrypted_password,
      reset_password_token: nil,
      reset_password_sent_at: nil,
      remember_created_at: nil,
      sign_in_count: :sign_in_count,
      current_sign_in_at: :current_sign_in_at,
      last_sign_in_at: :last_sign_in_at,
      current_sign_in_ip: :current_sign_in_ip,
      last_sign_in_ip: :last_sign_in_ip,
      confirmation_token: nil,
      confirmed_at: nil,
      confirmation_sent_at: nil,
      unconfirmed_email: nil,
      failed_attempts: :failed_attempts,
      unlock_token: nil,
      locked_at: nil,
      created_at: :created_at,
      updated_at: :updated_at,
      invitation_token: nil,
      invitation_created_at: nil,
      invitation_sent_at: nil,
      invitation_accepted_at: nil,
      invitation_limit: nil,
      invited_by_id: nil,
      invited_by_type: nil,
      invitation_count: nil,
      first_name: :first_name,
      last_name: :last_name,
      avatar: nil,
      username: nil,
      background_image: nil,
      background_image_top: nil,
      background_image_left: nil,
      roles_mask: nil,
      daily_sent_at: nil,
      weekly_sent_at: nil,
      authentication_token: nil,
      role: nil,
      second_email: nil,
      color: nil,
      is_show_tour: nil,
      tutorial_steps: nil
    }
  end

  def self.user_profile_map
    {
      id: :user_id,
      email: nil,
      encrypted_password: nil,
      reset_password_token: nil,
      reset_password_sent_at: nil,
      remember_created_at: nil,
      sign_in_count: nil,
      current_sign_in_at: nil,
      last_sign_in_at: nil,
      current_sign_in_ip: nil,
      last_sign_in_ip: nil,
      confirmation_token: nil,
      confirmed_at: nil,
      confirmation_sent_at: nil,
      unconfirmed_email: nil,
      failed_attempts: nil,
      unlock_token: nil,
      locked_at: nil,
      created_at: :created_at,
      updated_at: :updated_at,
      invitation_token: nil,
      invitation_created_at: nil,
      invitation_sent_at: nil,
      invitation_accepted_at: nil,
      invitation_limit: nil,
      invited_by_id: nil,
      invited_by_type: nil,
      invitation_count: nil,
      first_name: nil,
      last_name: nil,
      avatar: :avatar,
      username: nil,
      background_image: :background_image,
      background_image_top: nil,
      background_image_left: nil,
      roles_mask: nil,
      daily_sent_at: nil,
      weekly_sent_at: nil,
      authentication_token: nil,
      role: nil,
      second_email: nil,
      color: nil,
      is_show_tour: nil,
      tutorial_steps: nil
    }
  end

  def self.domain_map
    {
      id: :id,
      name: :name,
      logo: nil,
      background: nil,
      active: nil,
      user_id: :user_id,
      created_at: :created_at,
      updated_at: :updated_at
    }
  end

  def self.hive_map
    {
      id: :id,
      user_id: :user_id,
      title: :title,
      description: :description,
      created_at: :created_at,
      updated_at: :updated_at,
      is_public: nil,
      is_on_profile: nil,
      allow_add_pocket: nil,
      allow_friend_share: nil,
      pictures_count: nil,
      background_image: nil,
      slug: nil,
      sharing_type: nil,
      is_private: nil,
      shared_all_friends: nil,
      shared_select_friends: nil,
      domain_id: nil,
      background_color: nil
    }
  end

  def self.hive_embedded_map
    {
      id: :topic_id,
      user_id: :user_id,
      title: nil,
      description: nil,
      created_at: nil,
      updated_at: nil,
      is_public: nil,
      is_on_profile: nil,
      allow_add_pocket: nil,
      allow_friend_share: nil,
      pictures_count: nil,
      background_image: :background_image,
      slug: nil,
      sharing_type: nil,
      is_private: nil,
      shared_all_friends: nil,
      shared_select_friends: nil,
      domain_id: nil,
      background_color: nil
    }
  end

  def self.follow_map
    {
      id: :id,
      followable_id: :followable_id,
      followable_type: :followable_type,
      follower_id: :follower_id,
      follower_type: :follower_type,
      blocked: nil,
      created_at: :created_at,
      updated_at: :updated_at,
      reason: nil,
      message: nil,
      domain_id: nil
    }
  end

  def self.share_map
    {
      id: :id,
      shareable_object_type: :shareable_object_type,
      shareable_object_id: :shareable_object_id,
      sharing_object_type: :sharing_object_type,
      sharing_object_id: :sharing_object_id,
      user_id: :user_id,
      created_at: :created_at,
      updated_at: :updated_at,
      domain_id: nil
    }
  end

  def self.object_setting_map
    {
      id: nil,
      object_setting_id: :topic_id,
      object_setting_type: nil,
      user_id: :user_id,
      is_private: :share_public,
      background_image: :background_image,
      created_at: :created_at,
      updated_at: :updated_at,
      domain_id: nil
    }
  end

  def self.pocket_map
    {
      id: :old_subtopic_id,
      title: :title,
      description: nil,
      is_public: nil,
      is_on_profile: nil,
      allow_add_tip: nil,
      allow_friend_share: nil,
      created_at: :created_at,
      updated_at: :updated_at,
      user_id: :user_id,
      slug: nil,
      background_image: nil,
      is_asking_for_tips: nil,
      is_private: nil,
      shared_all_friends: nil,
      shared_select_friends: nil,
      domain_id: nil
    }
  end

  def self.tip_map
    {
      id: :id,
      title: :title,
      description: :body,
      user_id: :user_id,
      parent_id: nil,
      lft: nil,
      rgt: nil,
      created_at: :created_at,
      updated_at: :updated_at,
      is_public: :share_public,
      longitude: nil,
      latitude: nil,
      address: nil,
      location: nil,
      pictures_count: nil,
      comments_count: nil,
      slug: nil,
      cached_votes_total: nil,
      cached_votes_score: nil,
      cached_votes_up: nil,
      cached_votes_down: nil,
      cached_weighted_score: nil,
      sharing_type: nil,
      question_id: nil,
      links_count: nil,
      is_private: nil,
      shared_all_friends: :share_following,
      shared_select_friends: nil,
      domain_id: nil,
      deleted_at: nil,
      destroyer_id: nil,
      access_key: nil,
      draft: nil,
      color: nil
    }
  end

  def self.question_map
    {
      id: :id,
      name: :body,
      user_id: :user_id,
      created_at: :created_at,
      updated_at: :updated_at,
      library: nil,
      sent_at: nil,
      comments_count: nil,
      sharing_type: nil,
      cached_votes_total: nil,
      cached_votes_score: nil,
      cached_votes_up: nil,
      cached_votes_down: nil,
      cached_weighted_score: nil,
      is_public: :share_public,
      is_private: nil,
      shared_all_friends: :share_following,
      shared_select_friends: nil,
      domain_id: nil,
      access_key: nil,
      pictures_count: nil,
      color: nil,
      anonymously: nil
    }
  end

  def self.comment_map
    {
      id: :id,
      commentable_id: :commentable_id,
      commentable_type: :commentable_type,
      title: :title,
      body: :body,
      subject: :subject,
      user_id: :user_id,
      parent_id: :parent_id,
      lft: :lft,
      rgt: :rgt,
      created_at: :created_at,
      updated_at: :updated_at,
      longitude: :longitude,
      latitude: :latitude,
      address: :address,
      location: :location,
      domain_id: nil
    }
  end

  def self.picture_map
    {
      id: :id,
      user_id: :user_id,
      image: :file,
      image_type: nil,
      imageable_id: :attachable_id,
      imageable_type: :attachable_type,
      title: nil,
      created_at: :created_at,
      updated_at: :updated_at,
      domain_id: nil,
    }
  end

  def self.file_upload_map
    {
      id: nil,
      user_id: :user_id,
      file: :file,
      fileable_id: :attachable_id,
      fileable_type: :attachable_type,
      title: nil,
      created_at: :created_at,
      updated_at: :updated_at,
      domain_id: nil,
      old_file_upload_id: :old_resource_id
    }
  end

  def self.vote_map
    {
      id: :id,
      vote_flag: :vote_flag,
      votable_id: :votable_id,
      votable_type: :votable_type,
      voter_id: :voter_id,
      voter_type: :voter_type,
      created_at: :created_at,
      updated_at: :updated_at,
      vote_weight: :vote_weight,
      vote_scope: :vote_scope,
      domain_id: nil
    }
  end
end



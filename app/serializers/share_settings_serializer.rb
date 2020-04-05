class ShareSettingsSerializer < ActiveModel::Serializer
  attribute :id

  has_many :user_followers
  has_many :group_followers
  has_many :list_followers

  def user_followers
    settings = object.share_settings.where(user: scope, shareable_object_type: 'User')
    users = User.where(id: settings.map(&:shareable_object_id))

    user_followers = users.map do |user|
      {
        id: user.id,
        type: 'users'
      }
    end

    user_followers
    # [{ id: 1, type: 'users' }, { id: 3, type: 'users' }]
  end
end

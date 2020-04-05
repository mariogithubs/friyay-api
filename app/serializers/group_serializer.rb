class GroupSerializer < ActiveModel::Serializer
  attributes :title, :description, :slug, :color_index

  has_many :user_followers

  def user_followers
    object.user_followers.collect do |user|
      build_user_json(user)
    end
  end

  private

  def build_user_json(user)
    {
      id: user.id,
      name: user.name
    }
  end
end

class FollowSerializer
  include FastJsonapi::ObjectSerializer
  set_type :follows
  attributes :follower_type, :follower_id, :followable_type, :followable_id

  belongs_to :follower
  belongs_to :followable
end

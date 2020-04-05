class OrderSerializer < ActiveModel::Serializer
  attributes :title, :is_public

  has_many :users
  has_many :topic_orders

end

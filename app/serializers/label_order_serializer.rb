class LabelOrderSerializer < ActiveModel::Serializer
  attributes :name, :order, :is_default

  has_many :users, serializer: UserSerializerAMS

  def order
  	object.order.map(&:to_s)
  end	
end

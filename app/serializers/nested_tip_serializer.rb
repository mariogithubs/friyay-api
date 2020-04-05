class NestedTipSerializer
  include FastJsonapi::ObjectSerializer

  set_type :nested_tips
  
  attributes :id, :title, :slug

  has_many :nested_tips, &:nested_tips
end

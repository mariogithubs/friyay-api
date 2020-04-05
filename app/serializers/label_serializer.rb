class LabelSerializer
  include FastJsonapi::ObjectSerializer
  set_type :labels
  
  attributes :name, :color, :kind, :label_category_ids

  has_many :label_categories
  # belongs_to :user
  # has_many :label_assignments
end

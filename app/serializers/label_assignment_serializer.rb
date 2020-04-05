class LabelAssignmentSerializer
  include FastJsonapi::ObjectSerializer
  
  belongs_to :label
  belongs_to :item
end

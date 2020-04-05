class TipAssignmentSerializer
  include FastJsonapi::ObjectSerializer

  set_type :tip_assignments

  attribute :tip_id do |object|
    object.tip_id.to_s
  end

  attribute :assignment_id do |object|
    object.assignment_id.to_s
  end

  attribute :assignment_type

end

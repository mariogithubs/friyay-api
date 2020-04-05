class LabelCategorySerializer < ActiveModel::Serializer
  attributes :name

  has_many :labels

  def labels
    object.labels.collect { |label| build_label_json(label) }
  end

  def build_label_json(label)
   {
     id: label.id,
     type: 'labels',
     attributes:
     {
       name: label.name,
       color: label.color,
       kind: label.kind,
       label_category_ids: label.label_category_ids,
     }
   }  
 end
end

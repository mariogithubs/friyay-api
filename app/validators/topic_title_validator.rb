class TopicTitleValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return true if record.is_root? && Topic.where(title: value).blank?

    record.errors[attribute] << (options[:message] || 'title must be unique')
    false
  end
end

class DomainNotReservedValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return true unless TipHive.reserved_domain?(value)

    record.errors[attribute] << (options[:message] || 'cannot be used')
    false
  end
end

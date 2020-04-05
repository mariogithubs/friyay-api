class FixHtmlEncoding < ActiveRecord::Migration
  def up
    resources = {
      topic: [:title, :description],
      tip: [:title, :body],
      comment: [:title, :body],
      question: [:title, :body]
    }

    resources.each do |resource, fields|
      say "Handling #{resource.to_s.pluralize} now."
      klass = resource.to_s.camelize.constantize
      objects = klass.first(20)

      objects.each do |object|
        fields.each do |object_field|
          print "."
          text = object.send(object_field)
          next if text.blank?
          object.update_attribute(object_field, CGI::unescapeHTML(text))
        end
      end
    end
  end

  def down
    # do nothing
  end
end

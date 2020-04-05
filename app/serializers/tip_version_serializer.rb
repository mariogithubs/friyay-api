class TipVersionSerializer
  include FastJsonapi::ObjectSerializer
  require 'differ'
 
  set_type :versions
  attributes :created_at

  attribute :tip do |record|
    (!record.next.present?) ? Tip.find(record.reify(dup: true).id) : record.next.reify
  end

  attribute :changed_by do |record|
    author = User.find_by_id(record.whodunnit)
    author.nil? ? nil : author.title
  end

  attribute :previous_tip do |record|
    return nil unless record.object.present?
    version_tip = record.reify(dup: true)
    tip = (!record.next.present?) ? Tip.find(version_tip.id) : record.next.reify(dup: true)
    diff(tip, version_tip)
  end

  def self.diff(tip1, tip2)
    diff_body = Differ.diff_by_word((tip1.body || ""), (tip2.body || "")) rescue ''
    diff_title = Differ.diff_by_word((tip1.title || ""), (tip2.title || "")) rescue ''
    tip1.body = diff_body.format_as(:html)
    tip1.title = diff_title.format_as(:html)
    return tip1
  end
end

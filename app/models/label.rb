# == Schema Information
#
# Table name: labels
#
#  id         :integer          not null, primary key, indexed
#  user_id    :integer
#  name       :string
#  color      :string           indexed
#  kind       :string           indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Label < ActiveRecord::Base
  belongs_to :user
  has_many :label_assignments, dependent: :destroy

  validates :kind, inclusion: { in: %w(public private system) }
  validates :user_id, presence: true
  validates :name, :presence => true, :uniqueness => true

  scope :system_kind, -> { where(kind: 'system') }
  scope :private_kind, -> (user_id) { where(kind: 'private', user: user_id) }
  scope :public_kind, -> { where(kind: 'public') }
  scope :archived, -> { find_by(kind: 'system', name: 'archived') }

  has_and_belongs_to_many :label_categories, join_table: :labels_label_categories

  def self.create_default_labels
    system_labels = %w(archived)

    system_labels.each_with_index do |system_label, index|
      create(user_id: 0, kind: 'system', name: system_label, color: index)
    end
  end
end

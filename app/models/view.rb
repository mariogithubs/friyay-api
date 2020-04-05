# == Schema Information
#
# Table name: views
#
#  id               :integer          not null, primary key
#  user_id          :integer          default(0), not null, indexed
#  kind             :string
#  name             :string
#  settings         :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  show_nested_tips :boolean          default(TRUE), not null
#

class View < ActiveRecord::Base
  belongs_to :user
  has_many :view_assignments
  has_many :allocated_users, through: :view_assignments, source: :user

  validates :user_id, :kind, :name, presence: true
  validates :name, uniqueness: true

  scope :system, -> { where(kind: 'system') }
  scope :default_view, -> { find_by(name: 'grid') }

  VIEW_KINDS = %w(system user)

  def self.create_default_views
    starting_views = ['grid', 'small grid', 'list', 'sheet', 'task', 'wiki', 'kanban', 'card']
    no_nested_tip_views = ['task']

    starting_views.each do |view|
      new_view = View.new(kind: 'system', name: view, user_id: 0)
      new_view[:show_nested_tips] = false if no_nested_tip_views.include?(view)

      new_view.save
    end
  end
end

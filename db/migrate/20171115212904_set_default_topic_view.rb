class SetDefaultTopicView < ActiveRecord::Migration
  def up
    default_view = View.find_by(name: 'grid')

    Topic.where(default_view_id: nil)
         .update_all(default_view_id: default_view.id)
  end

  def down
    default_view = View.find_by(name: 'grid')

    Topic.where(default_view_id: default_view.id)
         .update_all(default_view_id: nil)
  end
end

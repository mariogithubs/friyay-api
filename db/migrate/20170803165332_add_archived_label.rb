class AddArchivedLabel < ActiveRecord::Migration
  def change
    # currently the only default label
    Label.create(user_id: 0, kind: 'system', name: 'archived', color: 1)
  end
end

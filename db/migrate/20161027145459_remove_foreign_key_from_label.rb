class RemoveForeignKeyFromLabel < ActiveRecord::Migration
  def up
    # NOTE: YOU MAY HAVE TO OPEN YOUR POSTGRES DATABASE AND
    # \d labels TO GET THE NAME OF YOUR FOREIGN KEY
    # BUT ONLY IF THE MIGRATION FAILS AND SAYS IT CAN'T FIND THE KEY
    remove_foreign_key :labels, name: 'fk_rails_9ea980b469'
    remove_foreign_key :label_assignments, name: 'fk_rails_ab21b8172e'
  end

  def down
    add_foreign_key :labels, :users
    add_foreign_key :label_assignments, :labels
  end
end

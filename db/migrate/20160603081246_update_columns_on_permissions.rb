class UpdateColumnsOnPermissions < ActiveRecord::Migration
  def up
  #   remove_column :activity_permissions, :action
  #   remove_column :activity_permissions, :description
  #   remove_column :activity_permissions, :subject_class
  #   remove_column :activity_permissions, :subject_role
  #   remove_column :activity_permissions, :user_id

  #   add_column :activity_permissions, :topic_id, :integer
  #   add_column :activity_permissions, :type, :string, default: 'DomainPermission'
  #   add_column :activity_permissions, :access_hash, :text, default: ActivityPermission::DEFAULT_ACCESS_HASH
  end

  def down
    add_column :activity_permissions, :action, :string
    add_column :activity_permissions, :description, :text
    add_column :activity_permissions, :subject_class, :string
    add_column :activity_permissions, :subject_role, :string
    add_column :activity_permissions, :user_id, :integer

    remove_column :activity_permissions, :topic_id
    remove_column :activity_permissions, :type
    remove_column :activity_permissions, :access_hash
  end
end

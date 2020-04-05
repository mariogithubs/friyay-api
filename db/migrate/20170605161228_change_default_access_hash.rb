class ChangeDefaultAccessHash < ActiveRecord::Migration
  def change
    if column_exists? :activity_permissions, :access_hash
      change_column_default :activity_permissions, :access_hash, {}
    else
      remove_column :activity_permissions, :action
      remove_column :activity_permissions, :description
      remove_column :activity_permissions, :subject_class
      remove_column :activity_permissions, :subject_role
      remove_column :activity_permissions, :user_id

      add_column :activity_permissions, :topic_id, :integer
      add_column :activity_permissions, :type, :string, default: 'DomainPermission'
      add_column :activity_permissions, :access_hash, :text, default: {}
    end
  end
end

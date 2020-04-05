class AddCaseInsensitiveUniqueIndexes < ActiveRecord::Migration
  def change
    remove_index :users, :email
    remove_index :tips, :title
    remove_index :domains, :tenant_name
    remove_index :domains, :name

    add_index :attachments, [:attachable_type, :attachable_id], name: 'index_attachments_on_attachable'
    add_index :domains, :tenant_name, case_sensitive: false, unique: true
    add_index :groups, :title, case_sensitive: false
    add_index :notifications, [:notifiable_type, :notifiable_id]
    add_index :share_settings, [:shareable_object_type, :shareable_object_id], name: 'index_share_settings_on_shareable_object'
    add_index :share_settings, [:sharing_object_type, :sharing_object_id], name: 'index_share_settings_on_sharing_object'
    add_index :tips, :title, case_sensitive: false
    add_index :topic_preferences, [:topic_id, :user_id]
    add_index :topics, [:title, :ancestry], case_sensitive: false, unique: true
    add_index :user_profiles, :user_id
    add_index :users, :email, case_sensitive: false, unique: true
  end
end

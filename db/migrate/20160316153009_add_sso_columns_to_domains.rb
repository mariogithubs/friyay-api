class AddSsoColumnsToDomains < ActiveRecord::Migration
  def change
    add_column :domains, :sso_enabled, :boolean, default: false
    add_column :domains, :idp_entity_id, :string
    add_column :domains, :idp_sso_target_url, :string
    add_column :domains, :idp_slo_target_url, :string
    add_column :domains, :idp_cert, :text
  end
end

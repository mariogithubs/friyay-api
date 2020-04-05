class SetAllFollowingForCurrentUsers < ActiveRecord::Migration
  def up
    Domain.all.each do |domain|
      begin
        Apartment::Tenant.switch domain.tenant_name do
          DomainMember.all.each do |dm|
            dm.user_profile.follow_all_topics!
            dm.user_profile.follow_all_domain_members!
          end
        end
      rescue
        next
      end
    end
  end

  def down

  end
end

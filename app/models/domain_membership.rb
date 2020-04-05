# == Schema Information
#
# Table name: public.domain_memberships
#
#  id              :integer          not null, primary key
#  user_id         :integer          not null, indexed
#  domain_id       :integer          not null, indexed
#  role            :string           default("member"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  invitation_id   :integer          indexed
#  active          :boolean          default(TRUE), not null
#  upgrade_to_role :string
#

class DomainMembership < ActiveRecord::Base
  belongs_to :user
  belongs_to :domain_member, foreign_key: :user_id
  belongs_to :domain

  validates :role, inclusion: { in: %w(member guest power) }

  scope :active, -> { where(active: true) }

  def invitation(tenant_name = domain.tenant_name)
    Apartment::Tenant.switch tenant_name do
      begin
        Invitation.find invitation_id
      rescue ActiveRecord::RecordNotFound
        return nil
      end
    end
  end
  # TODO: Need to add owner and admin to roles

  def activate!
    update_attribute(:active, true)
  end

  def deactivate!
    update_attribute(:active, false)
  end
end

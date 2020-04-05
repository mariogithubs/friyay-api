# == Schema Information
#
# Table name: public.users
#
#  id                     :integer          not null, primary key, indexed
#  email                  :string           default(""), not null, indexed
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string           indexed
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string           indexed
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string           indexed
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  first_name             :string
#  last_name              :string
#  username               :string           not null, indexed
#  order_id               :integer          indexed
#

class DomainMember < User
  # NOTE: There is a default scope on this model. see below

  scope :active, -> { where(domain_memberships: { active: true }) }

  searchable do
    text :name, :title

    string(:name) { name.downcase }

    string :kind do
      self.class.name
    end

    # string :domains, multiple: true do
    #   domains.pluck(:tenant_name)
    # end
    string :tenant_name do
      Apartment::Tenant.current
    end
  end

  def self.default_scope
    return all if Apartment::Tenant.current == 'public'

    joins(:domain_memberships)
      .where(domain_memberships: { domain_id: current_domain_id })
      .order(:id)
  end

  def activate!
    domain_memberships.where(domain_id: DomainMember.current_domain_id).update_all(active: true)
  end

  def deactivate!
    domain_memberships.where(domain_id: DomainMember.current_domain_id).update_all(active: false)
  end

  def self.current_domain_id
    Domain.select(:id).find_by(tenant_name: Apartment::Tenant.current)
  end
end

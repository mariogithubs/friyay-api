# == Schema Information
#
# Table name: roles
#
#  id            :integer          not null, primary key, indexed
#  name          :string           indexed, indexed => [resource_type, resource_id]
#  resource_id   :integer          indexed => [name, resource_type], indexed
#  resource_type :string           indexed => [name, resource_id], indexed
#  created_at    :datetime
#  updated_at    :datetime
#

# TODO: There is a problem here with multi-tenancy.
# Technically, domain_roles should only exist in the public schema
# whereas resource_roles should be in each tenant
# so, right now, we have weird things where some tenant schemas have many domain_roles
# but they should only have one, OR we should use the public schema for the domain_role.
# Most disturbing, is it doesn't seem to matter, b/c nothing we're currently using is broken by this
# However, as of August 21, 2017, we now need to have a list of roles for each domain (admin, guest)
# that can be assigned to users.

# TODO: we need to review Role, Permissions, MemberType(not a resource yet) because we have
# a guest Role and a guest membership type because a "member" and a "guest member" are different
# and a "guest member" has a role of "guest". we either need to run all permissions through the role of guest
# or make membership types a real resource. The problem comes from the fact that we can't have a
# "member" that has a "guest role" because we assume things about a member that we don't check against the Role
# ... I think. DomainMembership has a :role attr that is not the same thing as a Role instance

# so, one thing we need to untangle (thanks for letting me talk it through) is Roles. DomainMembership has an
# attribute, `:role` which is not the same thing as a `Role`. I think we have a lot of code on the front end that
# looks at the `:role` of the membership of the user that we may need to refactor to look at the role assignment.
# There's too much code to keep in my head, but I think that's the case. Due to this, a Guest is someone who has both
# `DomainMembership.where(role: 'guest')` and `current_domain.roles.where{ name: 'guest' }`

class Role < ActiveRecord::Base
  DOMAIN_TYPES = %w(admin member guest power)
  RESOURCE_TYPES = %w(admin moderator guest)
  TYPES = DOMAIN_TYPES | RESOURCE_TYPES

  # rubocop:disable Rails/HasAndBelongsToMany
  has_and_belongs_to_many :users, join_table: :users_roles
  # rubocop:enable Rails/HasAndBelongsToMany

  belongs_to :resource,
             polymorphic: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  validates :name,
            inclusion: { in: TYPES },
            allow_nil: false

  scopify

  def self.current_for_domain(domain_id)
    role = find_by(resource_type: 'Domain', resource_id: domain_id)
    role || Role.new(name: 'member')
  end
end

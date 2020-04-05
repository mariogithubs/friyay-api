module V2
  class DomainsController < ApplicationController
    before_action :authenticate_user!, except: [:show, :search]

    def index
      # domains = current_user.domains.order('LOWER(name)').includes([:user, :domain_permission, :users_roles])
      domains = current_user.domains
                .joins(:domain_memberships)
                .where(:domain_memberships => {:active => true})
                .includes([:user, :domain_permission, :users_roles])
                .order('LOWER(domains.name)')

      render json: domains, status: :ok
    end

    def search
      render_errors('Please Provide Search Term') && return unless params.key?(:filter)

      domains = Domain.filter(params[:filter])
      render json: domains, each_serializer: DomainSimpleSerializer, status: :ok
    end

    def show
      domain = Domain.find_by(tenant_name: params[:tenant_name])

      render json: domain, status: :ok
    end

    def create
      domain = Domain.new({ user_id: current_user.id }.merge(domain_params[:attributes]))

      load_domain_permission(domain)

      domain.save

      render_errors(domain.errors.full_messages) && return if domain.errors.any?

      load_roles(domain)

      render json: domain, status: :created
    end

    def update
      domain = Domain.find_by(id: params[:id])

      ability = Ability.new(current_user, domain)

      fail CanCan::AccessDenied unless ability.can?(:update, domain)

      domain.attributes = domain_params[:attributes]

      load_domain_permission(domain)

      domain.save

      render_errors(domain.errors.full_messages) && return if domain.errors.any?

      load_roles(domain)

      render json: domain, status: :ok, location: [:v2, domain]
    end

    def add_user
      fail CanCan::AccessDenied unless current_user.admin_of?(current_domain)

      user = User.find_by_id(params[:user_id])

      render_errors('User not found') && return unless user

      domain_membership = MembershipService.new(current_domain, user).join

      render json: domain_membership
    end

    def remove_user
      fail CanCan::AccessDenied unless current_user.admin_of?(current_domain)

      user = User.find_by_id(params[:user_id])
      render_errors('User not found') && return unless user

      MembershipService.new(current_domain, user).leave!
      ContentService.reassign(current_domain, user.id, params[:reassign_user_id])

      render json: {}, status: :ok
    end

    def join
      domain = Domain.find_by(tenant_name: params[:tenant_name])
      render_errors('Domain not found') && return unless domain

      domain_joined, domain_joined_message = domain.add_user(current_user)
      render_errors(domain_joined_message) && return unless domain_joined == true

      render json: domain, status: :ok, location: [:v2, domain]
    end

    def delete_hive
      fail CanCan::AccessDenied unless current_user.admin_of?(current_domain)
      domain = Domain.find_by(id: params[:id])

      render_errors('Could not archive topic') && return unless domain.delete(params)

      render json: {}, status: ok
    end

    def archive_hive
      fail CanCan::AccessDenied unless current_user.admin_of?(current_domain)
      domain = Domain.find_by(id: params[:id])

      render_errors('Could not archive topic') && return unless domain.archive(params)

      render json: {}, status: ok
    end  

    private

    def load_domain_permission(domain)
      return unless domain_params_has_data_for(:domain_permission)

      domain.domain_permission_attributes = domain_params[:relationships][:domain_permission][:data]
    end

    def load_roles(domain)
      return unless domain_params_has_data_for(:roles)

      domain_params[:relationships][:roles][:data].each do |role|
        user = User.find(role[:user_id])

        next unless user
        next unless role?(role[:name])

        if role[:_destroy]
          next if removing_owner?(domain, role[:name], user)
          user.remove_role role[:name], domain
        else
          user.add_role role[:name], domain
        end
      end
    end

    def role?(name)
      Role::TYPES.include?(name)
    end

    def removing_owner?(domain, role, user)
      domain.user == user && role.to_sym == :admin
    end

    # rubocop:disable Metrics/MethodLength
    def domain_params
      params.require(:data).permit(
        :type,
        attributes: [
          :name, :tenant_name, :logo, :background_image,
          :remote_logo_url, :remote_background_image_url, :join_type,
          :allow_invitation_request, :sso_enabled, :idp_entity_id,
          :idp_sso_target_url, :idp_slo_target_url, :idp_cert,
          :issuer, :default_view_id, :color,
          email_domains: []
        ],
        relationships: [
          domain_permission: [
            {
              data: [
                :id,
                access_hash: [
                  create_topic:     [roles: []],
                  edit_topic:       [roles: []],
                  destroy_topic:    [roles: []],
                  create_tip:       [roles: []],
                  edit_tip:         [roles: []],
                  destroy_tip:      [roles: []],
                  like_tip:         [roles: []],
                  comment_tip:      [roles: []],
                  create_group:     [roles: []],
                  edit_group:       [roles: []],
                  destroy_group:    [roles: []]
                ]
              ]
            }
          ],
          roles: [
            {
              data: [
                :name,
                :user_id,
                :_destroy
              ]
            }
          ]
        ]
      )
    end
    # rubocop:enable Metrics/MethodLength

    def domain_params_has_data_for(key)
      params_hash = domain_params.with_indifferent_access
      params_hash.key?(:relationships) &&
        params_hash[:relationships].key?(key) &&
        params_hash[:relationships][key].key?(:data) &&
        params_hash[:relationships][key][:data].size > 0
    end
  end
end

class InvitationSerializer < ActiveModel::Serializer
  attributes :user_id, :email, :invitation_type, :custom_message, :invitable_type, :invitable_id,
             :state, :first_name, :last_name

  belongs_to :invitable
end

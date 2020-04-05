# == Schema Information
#
# Table name: contact_informations
#
#  id              :integer          not null, primary key
#  first_name      :string
#  last_name       :string
#  company_name    :string
#  address         :string
#  appartment      :string
#  city            :string
#  country         :string
#  state           :string
#  zip             :string
#  subscription_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  domain_id       :integer
#

class ContactInformation < ActiveRecord::Base
  belongs_to :domain   
end

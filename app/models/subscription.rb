# == Schema Information
#
# Table name: subscriptions
#
#  id                     :integer          not null, primary key
#  stripe_subscription_id :string
#  start_date             :datetime
#  tenure                 :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  domain_id              :integer
#

class Subscription < ActiveRecord::Base
  belongs_to :domain

  validates_presence_of :domain_id, :tenure, :stripe_subscription_id
end

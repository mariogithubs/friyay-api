# == Schema Information
#
# Table name: public.subscription_plans
#
#  id             :integer          not null, primary key
#  name           :string
#  amount         :float
#  interval       :string
#  stripe_plan_id :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class SubscriptionPlan < ActiveRecord::Base
end

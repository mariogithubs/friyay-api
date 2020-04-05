# == Schema Information
#
# Table name: spam_records
#
#  id          :integer          not null, primary key
#  to          :string
#  from        :string
#  subject     :string
#  html        :text
#  spam_score  :string
#  spam_report :text
#  envelope    :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class SpamRecord < ActiveRecord::Base
end

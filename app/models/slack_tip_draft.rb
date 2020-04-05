# == Schema Information
#
# Table name: slack_tip_drafts
#
#  id              :integer          not null, primary key
#  title           :string
#  body            :text
#  is_draft        :boolean
#  slack_member_id :integer          indexed
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  tip_id          :integer
#

class SlackTipDraft < ActiveRecord::Base
  belongs_to :slack_member
end

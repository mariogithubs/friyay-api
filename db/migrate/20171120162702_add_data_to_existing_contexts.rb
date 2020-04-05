class AddDataToExistingContexts < ActiveRecord::Migration
  def up
    Context.all.each do |context|
      topic_id = context.topic_id || context.context_uniq_id[/:topic:([0-9]+)/, 1].to_i
      user_name = User.find_by(id: context.context_uniq_id[/user:([0-9]+)/, 1].to_i).try(:name)

      context.update_attributes(name: user_name, topic_id: topic_id)
    end
  end
end

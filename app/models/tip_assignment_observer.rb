class TipAssignmentObserver < ActiveRecord::Observer
  def after_create(tip_assignment)
    NotificationWorker.perform_in(1.second, 'someone_assigned_tip', tip_assignment.id, tip_assignment.class.to_s)
  end  
end
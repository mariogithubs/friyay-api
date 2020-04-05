class ViewAssignmentObserver < ActiveRecord::Observer
  def after_create(view)
    view.user.user_profile.increment_counter('total_views') 
  end

  def after_destroy(view)
    view.user.user_profile.decrement_counter('total_views') 
  end
end

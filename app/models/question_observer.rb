class QuestionObserver < ActiveRecord::Observer
  def after_create(question)
    NotificationWorker.perform_in(1.second, 'question', question.id, question.class.to_s)
  end
end

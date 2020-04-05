class VoteServiceWorker
  include Sidekiq::Worker

  def perform(action, opts = {})
    VoteService.send(action, opts)
  end
end

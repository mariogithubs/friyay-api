class TipExpirationWorker
  include Sidekiq::Worker

  def perform(action, tip_id)
    tip = Tip.find_by(id: tip_id)

    return unless tip

    tip.send(action)
  end
end

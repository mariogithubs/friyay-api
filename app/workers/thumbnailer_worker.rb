class ThumbnailerWorker
  include Sidekiq::Worker

  def perform(tip_link_id)
    tip_link = TipLink.find_by(id: tip_link_id)

    return unless tip_link
    tip_link.thumbnail_it
  end
end

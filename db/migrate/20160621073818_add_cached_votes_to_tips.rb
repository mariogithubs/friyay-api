class AddCachedVotesToTips < ActiveRecord::Migration
  def change
    add_column :tips, :cached_scoped_like_votes_total, :integer, default: 0
    add_column :tips, :cached_scoped_like_votes_score, :integer, default: 0
    add_column :tips, :cached_scoped_like_votes_up, :integer, default: 0
    add_column :tips, :cached_scoped_like_votes_down, :integer, default: 0
    add_column :tips, :cached_scoped_like_weighted_score, :integer, default: 0
    add_column :tips, :cached_scoped_like_weighted_total, :integer, default: 0
    add_column :tips, :cached_scoped_like_weighted_average, :float, default: 0.0
    add_index  :tips, :cached_scoped_like_votes_total
    add_index  :tips, :cached_scoped_like_votes_score
    add_index  :tips, :cached_scoped_like_votes_up
    add_index  :tips, :cached_scoped_like_votes_down
    add_index  :tips, :cached_scoped_like_weighted_score
    add_index  :tips, :cached_scoped_like_weighted_total
    add_index  :tips, :cached_scoped_like_weighted_average

    # TODO: add this to a rake task
    Tip.find_each(&:update_cached_votes)
  end
end

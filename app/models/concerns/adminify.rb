module Adminify
  extend ActiveSupport::Concern

  included do
    after_commit :make_admin
  end

  private

  def make_admin
    user.add_role 'admin', self
  end
end

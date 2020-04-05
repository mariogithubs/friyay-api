module MailObject
  class Invitation < MailObject::Base
    # TODO: THIS IS IN PREPARATION FOR A REFACTOR OF NOTIFICATIONS
    attr_reader :token

    def initialize(args = {})
      super(args)

      @token = args[:token]
    end
  end
end

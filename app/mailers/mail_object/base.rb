module MailObject
  class Base
    # TODO: THIS IS IN PREPARATION FOR A REFACTOR OF NOTIFICATIONS
    attr_reader :to, :from, :subject, :sender, :recipient, :domain, :hive, :group, :tip

    def initialize(args)
      @to = args[:to]
      @from = args[:from]
      @subject = args[:subject]
      @sender = args[:sender]
      @recipient = args[:recipient]
      @domain = args[:domain]
      @hive = args[:hive]
      @group = args[:group]
      @tip = args[:tip]
    end
  end
end

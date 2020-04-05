class EmailProcessor
  def initialize(email)
    @email = email
  end

  def process
    # Teefan - TODO: what is spam_record, and how is it related to @email?
    # @email instance here is the Griddler::Email class, which is located at
    # gems/griddler-1.3.1/lib/griddler/email.rb - which doesn't have spam_record method.
    #
    # process_spam && return unless @email.spam_record.blank?

    author = User.find_by_email(@email.from[:email])
    token  = fetch_token(@email.to)

    return if !author || token.blank?

    comment = Comment.find_by_message_identifier(token)

    return unless comment

    comment.commentable.comment_threads.create(
      body: @email.body,
      user_id: author.id
    )
  end

  def fetch_token(email_to)
    match = email_to.first[:token].match(/^comment-(.*)/i)

    return if match.blank?

    match.captures.first
  end

  def process_spam
    SpamRecord.create(
      to: @email.to,
      from: @email.from,
      subject: @email.subject,
      html: @email.html,
      spam_score: @email.spam_score,
      spam_report: @email.spam_report,
      envelope: @email.envelope
    )
  end
end

module Parse
  extend ActiveSupport::Concern

  URL_REGEXP = /^(http|https)?:(.)+/
  IMAGE_REGEX = %r{^(http|https)?:\/\/(.)+(png|jpg|jpeg|gif)+}
  FILESTACK_REGEX = %r{^(http|https)?:\/\/(.)+.filestackapi.com\/(.)+}
  SLACK_REGEXP = %r{^(http|https)?:\/\/(.)+.slack.com\/(.)+}
  # GOOGLE_REGEXP = %r{^(http|https)?:\/\/(www.)*(google(\.(.)+)+|goo.gl(\.(.)+)*)\/maps(.)+}
  MENTION_REGEXP = /(?<= |^|>)@([^@ \W]+)/
  # this is a new mention regex based on using
  # MENTION_REGEXP = %r{<span.*class=.*atwho-inserted.*>@(.*)<\/span>}

  included do
    # Teefan: as we're using Froala editor, we don't need to parse attachments
    # rather, we'll use Froala attachments management
    after_save :parse_body
  end

  private

  def parse_body
    Rails.logger.info("\n\n***** Parsing body ******\n\n")
    return unless self.body_changed?

    # ONLY parse mentions as we are not parsing tip body any more
    old_links, new_links = parse_urls(URL_REGEXP)

    # We want to remove google links from links so they do not create attachment
    # old_location_links, new_location_links = parse_urls(GOOGLE_REGEXP)
    # old_links -= old_location_links
    # new_links -= new_location_links

    old_slack_links, new_slack_links = parse_urls(SLACK_REGEXP)
    old_links -= old_slack_links
    new_links -= new_slack_links

    old_image_links, new_image_links = parse_urls(IMAGE_REGEX)
    old_links -= old_image_links
    new_links -= new_image_links

    old_image_links, new_image_links = parse_urls(FILESTACK_REGEX)
    old_links -= old_image_links
    new_links -= new_image_links

    old_mentions, new_mentions = parse_mentions(MENTION_REGEXP)

    self.is_a?(Comment) && Mention.add_and_remove(self, old_mentions, new_mentions)

    # Location.add_and_remove(self, old_location_links, new_location_links)
    SlackLink.add_and_remove(self, old_slack_links, new_slack_links)
    # Image.add_and_remove(self, old_image_links, new_image_links)

    add_and_remove_links(old_links, new_links)
  end

  def add_and_remove_links(old_links, new_links)
    return unless self.is_a?(Tip)

    TipLink.add_and_remove(self, old_links, new_links)
  end

  def parse_urls(regex)
    # clean up markdown escapes
    if body.present?
      body.gsub!('\_', '_')
      body.gsub!('\*', '*')
    end

    if body_was.present?
      body_was.gsub!('\_', '_')
      body_was.gsub!('\*', '*')
    end

    [scan(regex, body_was), scan(regex, body)]
  end

  # Returns an array of two arrays [[...old mentions...], [...new mentions...]]
  def parse_mentions(regex)
    mention_array = []
    mention_array << simple_scan(regex, body_was).map(&:downcase)
    mention_array << simple_scan(regex, body).map(&:downcase)

    Rails.logger.info("\n\n***** mentions: #{mention_array} ******\n\n")
    mention_array.compact
  end

  def simple_scan(regex, text)
    return [] if text.blank?

    text.scan(regex).flatten
  end

  def scan(regex, text)
    text ||= ''

    split_arr  = text.split(/\s+/)
    split_arr += text.split(/"+/)
    split_arr.uniq!

    urls = split_arr.find_all { |u| u =~ regex && uri?(u) }

    urls.compact
  end

  def uri?(string)
    uri = URI.parse(string)
    %w( http https ).include?(uri.scheme)
  rescue URI::BadURIError
    false
  rescue URI::InvalidURIError
    false
  end
end

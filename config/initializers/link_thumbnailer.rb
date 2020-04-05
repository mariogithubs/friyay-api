# Use this hook to configure LinkThumbnailer bahaviors.
LinkThumbnailer.configure do |config|
  # Numbers of redirects before raising an exception when trying to parse given url.
  #
  config.redirect_limit = 3

  # Set user agent
  #
  # rubocop:disable Metrics/LineLength
  # config.user_agent = 'link_thumbnailer'
  config.user_agent = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'

  # Enable or disable SSL verification
  #
  config.verify_ssl = true

  # The amount of time in seconds to wait for a connection to be opened.
  # If the HTTP object cannot open a connection in this many seconds,
  # it raises a Net::OpenTimeout exception.
  #
  # See http://www.ruby-doc.org/stdlib-2.1.1/libdoc/net/http/rdoc/Net/HTTP.html#open_timeout
  #
  config.http_open_timeout = 5

  # List of blacklisted urls you want to skip when searching for images.
  #
  config.blacklist_urls = [
    %r{^http://ad\.doubleclick\.net/},
    %r{^http://b\.scorecardresearch\.com/},
    %r{^http://pixel\.quantserve\.com/},
    %r{^http://s7\.addthis\.com/}
  ]

  # List of attributes you want LinkThumbnailer to fetch on a website.
  #
  # config.attributes = [:title, :images, :description, :videos, :favicon]
  config.attributes = [:title, :images, :description]

  # List of procedures used to rate the website description. Add you custom class
  # here. See wiki for more details on how to build your own graders.
  #
  # config.graders = [
  #   ->(description) { ::LinkThumbnailer::Graders::Length.new(description) },
  #   ->(description) { ::LinkThumbnailer::Graders::HtmlAttribute.new(description, :class) },
  #   ->(description) { ::LinkThumbnailer::Graders::HtmlAttribute.new(description, :id) },
  #   ->(description) { ::LinkThumbnailer::Graders::Position.new(description, weight: 3) },
  #   ->(description) { ::LinkThumbnailer::Graders::LinkDensity.new(description) }
  # ]

  # Minimum description length for a website.
  #
  config.description_min_length = 25

  # Regex of words considered positive to rate website description.
  #
  config.positive_regex = /article|body|content|entry|hentry|main|pages|pagination|post|text|blog|story/i

  # Regex of words considered negative to rate website description.
  #
  config.negative_regex = /combx|comment|com-|contact|foot|footer|footnote|masthead|media|meta|outbrain|promo|related|scroll|shoutbox|sidebar|sponsor|shopping|tags|tool|widget|modal/i

  # Numbers of images to fetch. Fetching too many images will be slow.
  # Note that LinkThumbnailer will only sort fetched images between each other.
  # Meaning that they could be a "better" image on the pages.
  #
  config.image_limit = 5

  # Whether you want LinkThumbnailer to return image size and type or not.
  # Setting this value to false will increase performance since for each images, LinkThumbnailer
  # does not have to fetch its size and type.
  #
  # config.image_stats = true
  #
  # Whether you want LinkThumbnailer to raise an exception if the Content-Type of the HTTP request
  # is not an html or xml.
  #
  # config.raise_on_invalid_format = false
  #
  # Sets number of concurrent http connections that can be opened to fetch images informations such as size and type.
  #
  # config.max_concurrency = 20
  # rubocop:enable Metrics/LineLength
end

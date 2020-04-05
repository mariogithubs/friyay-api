module EmailsHelper
  def strip_version(url)
    url.gsub(%r{\/v2\/}, '/')
  end

  def protocol_helper
    ENV['PROTOCOL'] || 'https'
  end
end

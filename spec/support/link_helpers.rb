module LinkHelpers
  def build_test_google_links
    prefixes = [
      'https://www.google.com',
      'http://www.google.com',
      'https://www.google.co.in',
      'https://www.google.com.br',
      'https://www.google.at',
      'https://www.google.dk',
      'https://google.com.gh'
    ]

    # rubocop:disable Metrics/LineLength
    full_location = '/maps/place/Gole+Market,+New+Delhi,+Delhi+110001,+India/@28.6349602,77.1955057,15z/data=!3m1!4b1!4m2!3m1!1s0x390cfd5a94a5aa29:0xd42251c7966e83f5?hl=en'
    # rubocop:enable Metrics/LineLength

    links = prefixes.map { |prefix| prefix + full_location }

    # Also test if someone drops in an iframe
    # rubocop:disable Metrics/LineLength
    links << '<iframe src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d14007.306193795639!2d77.19550573198815!3d28.634960168667508!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x390cfd5a94a5aa29%3A0xd42251c7966e83f5!2sGole+Market%2C+New+Delhi%2C+Delhi+110001%2C+India!5e0!3m2!1sen!2sus!4v1452002987716" width="600" height="450" frameborder="0" style="border:0" allowfullscreen></iframe>'
    # rubocop:enable Metrics/LineLength

    links
  end

  def build_test_links
    [
      'http://www.apple.com',
      'https://www.tiphive.com',
      'https://answers.yahoo.com/',
      'https://answers.yahoo.com/dir/index?sid=396545311',
      'http://mozy.com/blog/wp-uploads/2013/06/interactive_infographic/',
      'http://home.snafu.de/tilman/xenulink.html'
    ]
  end

  def build_test_image_links
    [
      'http://www.networkforgood.com/wp-content/uploads/2015/08/bigstock-Test-word-on-white-keyboard-27134336.jpg',
      'https://www.bcbe.org/cms/lib08/AL01901374/Centricity/Domain/3689/Teaching%20To%20The%20Test.gif',
      'https://pixabay.com/static/uploads/photo/2015/03/12/12/43/test-670091_960_720.png'
    ]
  end

  def build_test_slack_links
    [
      'https://tiphive.slack.com/archives/development/p1463546408000034',
      'https://tiphive.slack.com/archives/development/p1463544572000007'
    ]
  end
end

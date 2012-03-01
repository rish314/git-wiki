
require 'mixlib/config'

module GitWiki
  class Config
    extend(Mixlib::Config)

    homepage            'Home'
    extension           ''
    repository          "#{ENV['HOME']}/wiki"

    cookie_key          'gitwiki.session'
    cookie_domain       nil
    cookie_path         '/'
    cookie_expire_after 86400 * 14
    cookie_secret       'SETTHIS'

  end
end

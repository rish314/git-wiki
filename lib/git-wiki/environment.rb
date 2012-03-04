
require 'mixlib/config'

module GitWiki
  class Environment
    extend(Mixlib::Config)

    homepage            'home'
    extension           '.md'
    repository          "#{ENV['HOME']}/wiki"
    attachments_dir     "_attachments"

    cookie_key          'gitwiki.session'
    cookie_domain       nil
    cookie_path         '/'
    cookie_expire_after 86400 * 14
    cookie_secret       'SETTHIS'

    htpasswd_file       File.join(File.dirname(__FILE__), '..', '..', 'htpasswd')
  end
end

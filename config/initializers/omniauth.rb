Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, Rails.application.secrets.twitter_provider_key, Rails.application.secrets.twitter_provider_secret
  provider :google_oauth2, Rails.application.secrets.google_provider_key, Rails.application.secrets.google_provider_secret
  provider :github, Rails.application.secrets.github_provider_key, Rails.application.secrets.github_provider_secret, scope: ""
  provider :ldap,
    :title      => Rails.application.secrets.ldap_provider_name,
    :host       => Rails.application.secrets.ldap_hostname,
    :port       => Rails.application.secrets.ldap_port,
    :method     => :plain,
    :base       => Rails.application.secrets.ldap_base,
    :bind_dn    => Rails.application.secrets.ldap_binddn,
    :password   => Rails.application.secrets.ldap_bindpwd
end

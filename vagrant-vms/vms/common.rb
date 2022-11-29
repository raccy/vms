# common for Vagrantfile

require 'digest/md5'
require 'uri'

def calc_port(name, range: (10_000..30_000))
  range.begin + (Digest::MD5.digest(name).unpack1('L') % range.size)
end

def get_proxy
  protocols = %i[all http https ftp].to_h do |name|
    value = ["VAGRANT_#{name.upcase}_PROXY", "#{name.upcase}_PROXY", "#{name}_proxy"]
            .map { |key| ENV[key] }.find(&:itself)
    [name, value]
  end.compact
  all_proxy = %i[all http https ftp].map { |name| protocols[name] }.find(&:itself)
  return if all_proxy.nil?

  no_proxy = %w[VAGRANT_NO_PROXY NO_PROXY no_proxy].map { |key| ENV[key] }.find(&:itself)

  proxy_env = {
    ALL_PROXY: all_proxy,
    HTTP_PROXY: protocols[:http],
    HTTPS_PROXY: protocols[:https],
    FTP_PROXY: protocols[:ftp],
    NO_PROXY: no_proxy,
  }.compact
  proxy_env = proxy_env.merge(proxy_env.transform_keys(&:downcase))
  proxy_uri = URI.parse(all_proxy)

  {
    uri: proxy_uri.to_s,
    scheme: proxy_uri.scheme,
    host: proxy_uri.host,
    port: proxy_uri.port,
    user: proxy_uri.user,
    password: proxy_uri.password,
    excludes: no_proxy.to_s.split(',').map(&:strip),
    no_proxy: no_proxy,
    env: proxy_env,
    **protocols,
  }
end

# user only
def git_config
  user = {}
  %i[name email].each do |name|
    value = `git config --get user.#{name}`.chomp
    user[name] = value if value && !value.empty?
  end
  {user: user}
end

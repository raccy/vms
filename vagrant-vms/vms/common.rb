# common for Vagrantfile

require "digest/md5"
require "uri"
require "etc"

if ENV["VAGRANT_WSL_ENABLE_WINDOWS_ACCESS"].to_i.positive?
  # DOSISH
  class << File
    alias_method :_dirname, :dirname unless defined? File._dirname
    def dirname(filename, ...)
      filename = filename.to_s
      if filename.include?("\\")
        _dirname(filename.gsub("\\", "/"), ...).gsub("/", "\\")
      else
        _dirname(filename, ...)
      end
    end

    alias_method :_basename, :basename unless defined? File._basename
    def basename(filename, ...)
      filename = filename.to_s
      if filename.include?("\\")
        _basename(filename.gsub("\\", "/"), ...).gsub("/", "\\")
      else
        _basename(filename, ...)
      end
    end

    alias_method :_join, :join unless defined? File._join
    def join(*item)
      item = item.map(&:to_s)
      if item.any? { |path| path.include?("\\") }
        _join(*item.map { |path| path.gsub("\\", "/") }).gsub("/", "\\")
      else
        _join(*item)
      end
    end
  end

  # WSL
  module FileUtils
    module_function def wslpath(path)
      `wslpath "#{path}"`.strip
    end

    module_function def path_on_wsl(list)
      if list.is_a?(Array)
        list.map { |path| path_on_wsl(path) }
      elsif list.to_s.include?("\\")
        wslpath(list)
      else
        list
      end
    end

    module_function alias_method(:_touch, :touch) unless defined? FileUtils._touch
    module_function def touch(list, ...)
      FileUtils._touch(path_on_wsl(list), ...)
    end

    module_function alias_method(:_cp, :cp) unless defined? FileUtils._cp
    module_function def cp(src, dest, ...)
      FileUtils._cp(path_on_wsl(src), path_on_wsl(dest), ...)
    end
    module_function alias_method(:copy, :cp)

    module_function alias_method(:_mv, :mv) unless defined? FileUtils._mv
    module_function def mv(src, dest, ...)
      FileUtils._mv(path_on_wsl(src), path_on_wsl(dest), ...)
    end
    module_function alias_method(:move, :mv)

    module_function alias_method(:_rm, :rm) unless defined? FileUtils._rm
    module_function def rm(list, ...)
      FileUtils_rm(path_on_wsl(list), ...)
    end
    module_function alias_method(:remvoe, :rm)

    module_function alias_method(:_rm_rf, :rm_rf) unless defined? FileUtils._rm_rf
    module_function def rm_rf(list, ...)
      FileUtils._rm_rf(path_on_wsl(list), ...)
    end
    module_function alias_method(:rmtree, :rm_rf)
  end
end

def calc_port(name, range: (10_000..30_000))
  range.begin + (Digest::MD5.digest(name).unpack1("L") % range.size)
end

def get_proxy
  protocols = %i[all http https ftp].to_h do |name|
    value = ["VAGRANT_#{name.upcase}_PROXY", "#{name.upcase}_PROXY", "#{name}_proxy"]
            .map { |key| ENV.fetch(key, nil) }.find(&:itself)
    [name, value]
  end.compact
  all_proxy = %i[all http https ftp].map { |name| protocols[name] }.find(&:itself)
  return if all_proxy.nil?

  no_proxy = ["VAGRANT_NO_PROXY", "NO_PROXY", "no_proxy"]
             .map { |key| ENV.fetch(key, nil) }.find(&:itself)

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
    excludes: no_proxy.to_s.split(",").map(&:strip),
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

def recommended_cpus
  if Etc.nprocessors < 4
    1
  elsif Etc.nprocessors < 8
    2
  else
    4
  end
end

def recommended_memory
  File.read("/proc/meminfo") =~ /^MemTotal:\s*(\d+) kB$/
  mem_total = $1.to_i / 1024 / 1024
  if mem_total.positive?
    ((mem_total - 8) / 2).clamp(2, 8) * 1024
  else
    4 * 1024
  end
rescue StandardError
  4 * 1024
end

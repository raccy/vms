class Setup
  DEFAULT_OPTIONS = {
    name: nil,
    distro: "Ubuntu",
    version: 2,
    username: nil,
    password: nil,
    location: nil,
    config_file: nil,
    playbooks: File.expand_path("../playbooks", __dir__),
    proxy: nil,
    http_proxy: nil, # ENV http_proxy or HTTP_PROXY
    https_proxy: nil, # ENV https_proxy or HTTPS_PROXY
    ftp_proxy: nil, # ENV ftp_proxy or FTP_PROXY
    no_proxy: nil, # ENV no_proxy or NO_PROXY
    skip_update: false,
    skip_ansible: false,
  }.freeze

  attr_reader :options

  def initialize(config_file, **opts)
    # default setup options
    @options = DEFAULT_OPTIONS.dup
    # load proxy settings from environment variables
    %i[http_proxy https_proxy ftp_proxy no_proxy].each do |key|
      @options[key] = ENV[key.to_s] || ENV.fetch(key.to_s.upcase, nil)
    end
    # load setup options from config file
    if config_file
      @options.merge!(YAML.load_file(config_file, symbolize_names: true).fetch(:setup, {}))
      @options[:config_file] = config_file
    end
    # override options
    @options.merge!(**opts)
    # normalize options
    @options[:name] ||= @options[:distro]
    @options[:version] = @options[:version].to_i
    if @options[:proxy]
      %i[http_proxy https_proxy ftp_proxy].each do |name|
        @options[name] ||= @options[:proxy]
      end
    end
    # freeze
    @options.freeze
  end

  def name
    options[:name]
  end

  def distro
    options[:distro]
  end

  def version
    options[:version]
  end

  def location
    options[:location] && File.expand_path(options[:location])
  end

  def root
    "//wsl.localhost/#{name}"
  end

  def config_file
    options[:config_file] && File.expand_path(options[:config_file])
  end

  def input_user?
    options[:username].nil? || options[:username].empty?
  end

  def proxy_uri
    %i[proxy http_proxy https_proxy ftp_proxy].map { |key| options[key] }.find(&:itself)
  end

  def proxy_required?
    !proxy_uri.nil?
  end

  def proxy_env
    options.slice(:http_proxy, :https_proxy, :ftp_proxy, :no_proxy)
  end

  def apt_opts
    @apt_opts ||=
      if proxy_required?
        %w[http https ftp]
          .map { |proto| [proto, options["#{proto}_proxy".intern]] }
          .select { |_, value| value }
          .map { |proto, value| "-o Acquire::#{proto}::Proxy=\"#{value}\" -o Acquire::#{proto}::Timeout=600" }
          .join(" ")
      else
        ""
      end
  end

  def dnf_opts
    @dnf_opts ||=
      if proxy_required?
        "--setopt=proxy=#{proxy_uri} --setopt=timeout=600"
      else
        ""
      end
  end

  def skip_update?
    options[:skip_update]
  end

  def skip_ansible?
    options[:skip_ansible]
  end
end

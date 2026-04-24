class Setup
  DEFAULT_OPTIONS = {
    name: nil,
    distro: "Ubuntu",
    version: 2,
    username: nil,
    groupname: nil,
    password: nil,
    location: nil,
    config_file: nil,
    ansible: "package",
    playbooks: File.expand_path("../playbooks", __dir__),
    proxy: nil,
    http_proxy: nil, # ENV http_proxy or HTTP_PROXY
    https_proxy: nil, # ENV https_proxy or HTTPS_PROXY
    ftp_proxy: nil, # ENV ftp_proxy or FTP_PROXY
    no_proxy: nil, # ENV no_proxy or NO_PROXY
    skip_update: false,
    skip_ansible: false,
  }.freeze

  DEFAULT_UID = 1000
  DEFAULT_GID = 1000
  DEFAULT_GROUPS = ["wheel", "adm", "cdrom", "sudo", "dip", "plugdev"].freeze

  attr_reader :options

  def initialize(config_file, **)
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
    @options.merge!(**)
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

  def config_file
    options[:config_file] && File.expand_path(options[:config_file])
  end

  def input_user?
    options[:username].nil? || options[:username].empty?
  end

  def username
    options[:username]
  end

  def groupname
    options[:groupname] || username
  end

  def password
    options[:password] || username
  end

  def uid
    Setup::DEFAULT_UID
  end

  def gid
    Setup::DEFAULT_GID
  end

  def groups
    Setup::DEFAULT_GROUPS
  end

  def proxy_uri
    %i[proxy http_proxy https_proxy ftp_proxy].map { |key| options[key] }.find(&:itself)
  end

  def proxy_required?
    !proxy_uri.nil?
  end

  def proxy_env
    @proxy_env ||= options.slice(:http_proxy, :https_proxy, :ftp_proxy, :no_proxy).compact
      .then { |env| env.merge(env.transform_keys(&:upcase)) }
  end

  def apt_opts
    @apt_opts ||=
      if proxy_required?
        ["http", "https", "ftp"]
          .map { |proto| [proto, options[:"#{proto}_proxy"]] }
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

  def install_ansible_cmds(pkg_mgr)
    case options[:ansible]
    in "package"
      case pkg_mgr
      in "apt"
        ["sudo apt install ansible -y #{apt_opts}"]
      in "dnf"
        ["sudo dnf install ansible-core -y #{dnf_opts}"]
      end
    in "pip"
      install_pip_cmds(pkg_mgr) + ["python3 -m pip install --user ansible"]
    in "pipx"
      install_pipx_cmds(pkg_mgr) + ["pipx install --include-deps ansible"]
    end
  end

  def install_pip_cmds(pkg_mgr)
    case pkg_mgr
    in "apt"
      ["sudo apt install python3-pip -y #{apt_opts}"]
    in "dnf"
      ["sudo dnf install python3-pip -y #{dnf_opts}"]
    end
  end

  def install_pipx_cmds(pkg_mgr)
    case pkg_mgr
    in "apt"
      ["sudo apt install pipx -y #{apt_opts}", "pipx ensurepath"]
    in "dnf"
      install_pip_cmds(pkg_mgr) + ["python3 -m pip install --user pipx", "python3 -m pipx ensurepath"]
    end
  end

  def playbooks
    File.expand_path(options[:playbooks])
  end

  def skip_update?
    options[:skip_update]
  end

  def skip_ansible?
    options[:skip_ansible]
  end

  # TODO: 複数の値に未対応
  def git_config
    @git_config ||= `git config --list --global`.lines
      .to_h { |line| line.chomp.split("=", 2) }
      .reject { |key, _| key.start_with?("filter.lfs.") }
      .except("safe.directory")
  end
end

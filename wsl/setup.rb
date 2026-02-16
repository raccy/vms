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

  def version
  end

  def location
    options[:location] && File.expand_path(options[:location])
  end

  def root
    "//wsl.localhost/#{name}"
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

  # wsl run helper methods
  def run_capture(cmd, encoding: Encoding::UTF_8, exception: false, stderr: :stderr, **)
    out, status =
      case stderr
      when :stderr
        Open3.capture2(cmd, binmode: true, **)
      when :stdout
        Open3.capture2e(cmd, binmode: true, **)
      when nil
        Open3.capture3(cmd, binmode: true, **).then { |out, _err, status| [out, status] }
      else
        raise "invalid stderr option: #{stderr}"
      end

    if status.success?
      out.encode(Encoding.default_internal || Encoding::UTF_8, encoding).gsub(/\R/, "\n")
    elsif exception
      raise "Failed to command: #{cmd}"
    end
  end

  def wsl_run(cmd, capture: false, exception: true, **opts)
    puts cmd
    wsl_cmd_opts = %i[distro user cd env].to_h { |key| [key, opts.delete(key)] }
    wsl_cmd = generate_wsl_cmd(cmd, **wsl_cmd_opts.compact)

    if capture
      run_capture(wsl_cmd, exception:, **opts)
    else
      system(wsl_cmd, exception:, **opts)
    end
  end

  # rubocop: disable Naming/MethodParameterName
  def generate_wsl_cmd(cmd, distro: name, user: nil, cd: nil, env: {})
    wsl_cmd = "wsl -d #{distro}"
    wsl_cmd << " -u #{user}" if user
    wsl_cmd << " --cd \"#{cd}\"" if cd
    wsl_cmd << " -- "
    env.each { |key, value| wsl_cmd << "#{key}=#{value} " }
    wsl_cmd << cmd
  end
  # rubocop: enable Naming/MethodParameterName

  def wsl_path(path, **)
    wsl_run("wslpath -u \"#{path}\"", capture: true, **).force_encoding(Encoding::UTF_8).chomp
  end

  def wsl_file_read(path, **)
    check_path(path)
    wsl_run("cat -- #{path}", capture: true, **)
  end

  def wsl_file_write(path, data, mode: nil, **)
    check_path(path)
    wsl_mkdir(File.dirname(path), **)
    wsl_run("tee -- #{path}", capture: true, stdin_data: data, **)
    wsl_chmod(path, mode) if mode
  end

  def wsl_file_append(path, data, mode: nil, **)
    check_path(path)
    wsl_mkdir(File.dirname(path), **)
    wsl_run("tee -a -- #{path}", capture: true, stdin_data: data, **)
    wsl_chmod(path, mode) if mode
  end

  def wsl_mkdir(path, mode: nil, **)
    check_path(path)
    wsl_run("mkdir -p -- #{path}", **)
    wsl_chmod(path, mode) if mode
  end

  def wsl_chmod(path, mode)
    check_path(path)
    check_mode(mode)
    wsl_run("chmod #{mode} -- #{path}")
  end

  def wsl_whoami
    wsl_run("whoami", capture: true).force_encoding(Encoding::UTF_8).chomp
  end

  # cache for wsl_pkg_mgr
  def wsl_pkg_mgr
    @wsl_pkg_mgr ||=
      ["apt", "dnf", "yum", "pacman", "apk", "zypper"].find do |mgr|
        result = wsl_run("which #{mgr}", capture: true, exception: false, stderr: nil)
        result && result.force_encoding(Encoding::UTF_8).chomp.length.positive?
      end
    end
  end

  def check_path(path)
    return if path =~ %r{\A[\w/.-]+\z}

    raise "invalid path: #{path}"
  end

  def check_mode(mode)
    return if mode =~ /\A([ugoa]*([-+=]([rwxXst]*|[ugo]))+|[-+=][0-7]+)\z/

    raise "invalid mode: #{mode}"
  end

  def get_wsl_status
    result = run_capture("wsl --status", encoding: Encoding::UTF_16LE)
    return if result.nil?

    {
      default: /^既定のディストリビューション: (\S+)$/.match(result)&.[](1),
      version: /^既定のバージョン: (\S+)$/.match(result)[1].to_i,
      enable_wsl1: !/^WSL1 は、現在のマシン構成ではサポートされていません。$/.match?(result),
    }
  end

  def get_wsl_list
    result = run_capture("wsl --list --all --verbose",
      encoding: Encoding::UTF_16LE)
    return {} if result.nil?

    parse_wsl_list(result).to_h { |d| [d[:name], d] }
  end

  def parse_wsl_list(list)
    list.lines.drop(1).map do |line|
      if (m = /^(.)\s+(\S+)\s+(\S+)\s+(\d)\s*$/.match(line))
        {default: m[1] == "*", name: m[2], state: m[3], version: m[4].to_i}
      else
        raise "invalid wsl list line: #{line}"
      end
    end
  end

  def get_wsl_registry
    list = {}
    open_lxss_registry do |reg|
      reg.each_key do |key, _wtime|
        next unless key =~ /^\{[\h-]+\}$/

        reg.open(key) do |sub|
          list[sub["DistributionName"]] =
            {key: key, uid: sub["DefaultUid"], path: sub["BasePath"]}
        end
      end
    end
    list
  end

  def open_lxss_registry(subkey = nil, mode: "r", &)
    key = 'Software\Microsoft\Windows\CurrentVersion\Lxss'
    key += "\\#{subkey}" if subkey
    desired = calc_mask(mode)
    Win32::Registry::HKEY_CURRENT_USER.open(key, desired, &)
  end

  def calc_mask(mode)
    desired = 0
    desired |= Win32::Registry::KEY_READ if mode.include?("r")
    desired |= Win32::Registry::KEY_WRITE if mode.include?("w")
    desired |= Win32::Registry::KEY_EXECUTE if mode.include?("x")
    desired
  end
end

class WSL
  def initialize(distro: nil, user: nil, cd: nil, env: {})
    @distro = distro
    @user = user
    @cd = cd
    @env = env
  end

  def run(cmd, capture: false, exception: true, **opts)
    puts cmd
    wsl_cmd_opts = opts.slice(:distro, :user, :cd, :env)
    opts = opts.except(:distro, :user, :cd, :env)
    wsl_cmd = generate_wsl_cmd(cmd, **wsl_cmd_opts.compact)

    if capture
      WSL.run_capture(wsl_cmd, exception:, **opts)
    else
      system(wsl_cmd, exception:, **opts)
    end
  end

  def path(path, **)
    run("wslpath -u \"#{path}\"", capture: true, **).force_encoding(Encoding::UTF_8).chomp
  end

  def file_read(path, **)
    check_path(path)
    run("cat -- #{path}", capture: true, **)
  end

  def file_write(path, data, mode: nil, **)
    check_path(path)
    mkdir(File.dirname(path), **)
    run("tee -- #{path}", capture: true, stdin_data: data, **)
    chmod(path, mode) if mode
  end

  def file_append(path, data, mode: nil, **)
    check_path(path)
    mkdir(File.dirname(path), **)
    run("tee -a -- #{path}", capture: true, stdin_data: data, **)
    chmod(path, mode) if mode
  end

  def mkdir(path, mode: nil, **)
    check_path(path)
    run("mkdir -p -- #{path}", **)
    chmod(path, mode) if mode
  end

  def chmod(path, mode, **)
    check_path(path)
    check_mode(mode)
    run("chmod #{mode} -- #{path}", **)
  end

  def whoami
    run("whoami", capture: true).force_encoding(Encoding::UTF_8).chomp
  end

  def pkg_mgr
    @pkg_mgr ||=
      ["apt", "dnf", "yum", "pacman", "apk", "zypper"].find do |mgr|
        result = run("which #{mgr}", capture: true, exception: false, stderr: nil)
        result && result.force_encoding(Encoding::UTF_8).chomp.length.positive?
      end
  end

  # wsl run helper methods
  private def check_path(path)
    return if path =~ %r{\A[\w/.-]+\z}

    raise "invalid path: #{path}"
  end

  private def check_mode(mode)
    return if mode =~ /\A([ugoa]*([-+=]([rwxXst]*|[ugo]))+|[-+=][0-7]+)\z/

    raise "invalid mode: #{mode}"
  end

  # rubocop: disable Naming/MethodParameterName
  private def generate_wsl_cmd(cmd, distro: @distro, user: @user, cd: @cd, env: @env)
    wsl_cmd = +"wsl"
    wsl_cmd << "  -d #{distro}" if distro
    wsl_cmd << " -u #{user}" if user
    wsl_cmd << " --cd \"#{cd}\"" if cd
    wsl_cmd << " -- "
    env.each { |key, value| wsl_cmd << "#{key}=#{value} " }
    wsl_cmd << cmd
    wsl_cmd
  end
  # rubocop: enable Naming/MethodParameterName

  # class methods
  class << self
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

    def clear
      @status = nil
      @list = nil
      @dict = nil
    end

    def status
      @status ||= run_capture("wsl --status", encoding: Encoding::UTF_16LE).then do |result|
        if result
          {
            default: /^既定のディストリビューション: (\S+)$/.match(result)&.[](1),
            version: /^既定のバージョン: (\S+)$/.match(result)[1].to_i,
            enable_wsl1: !/^WSL1 は、現在のマシン構成ではサポートされていません。$/.match?(result),
            enable_wsl2: true,
          }
        else
          {
            default: nil,
            version: nil,
            enable_wsl1: false,
            enable_wsl2: false,
          }
        end
      end
    end

    def distro(name)
      dict[name]
    end

    def dict
      @dict ||= list.to_h { |d| [d[:name], d] }
    end

    def list
      @list ||= merge_list(:name, wsl_list, registry_list)
    end

    private def merge_list(key, *lists)
      hash = Hash.new { |h, k| h[k] = {} }
      lists.each do |list|
        list.each do |v|
          hash[v[key]].merge!(v)
        end
      end
      hash.values
    end

    private def wsl_list
      run_capture("wsl --list --all --verbose", encoding: Encoding::UTF_16LE).then do |result|
        if result
          parse_wsl_list(result)
        else
          []
        end
      end
    end
    private def parse_wsl_list(list)
      list.lines.drop(1).map do |line|
        if (m = /^(.)\s+(\S+)\s+(\S+)\s+(\d)\s*$/.match(line))
          {default: m[1] == "*", name: m[2], state: m[3], version: m[4].to_i}
        else
          raise "invalid wsl list line: #{line}"
        end
      end
    end

    private def registry_list
      list = []
      open_lxss_registry do |reg|
        reg.each_key do |key, _wtime|
          next unless key =~ /^\{[\h-]+\}$/

          reg.open(key) do |sub|
            list << {name: sub["DistributionName"], key: key, uid: sub["DefaultUid"], path: sub["BasePath"]}
          end
        end
      end
      list
    end

    private def open_lxss_registry(subkey = nil, mode: "r", &)
      key = 'Software\Microsoft\Windows\CurrentVersion\Lxss'
      key += "\\#{subkey}" if subkey
      desired = calc_mask(mode)
      Win32::Registry::HKEY_CURRENT_USER.open(key, desired, &)
    end

    private def calc_mask(mode)
      desired = 0
      desired |= Win32::Registry::KEY_READ if mode.include?("r")
      desired |= Win32::Registry::KEY_WRITE if mode.include?("w")
      desired |= Win32::Registry::KEY_EXECUTE if mode.include?("x")
      desired
    end
  end
end

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
    run("wslpath -u \"#{path}\"", capture: true, **).chomp
  end

  def file_read(path, **)
    check_path(path)
    run("cat -- #{path}", capture: true, **)
  end

  def file_write(path, data, mode: nil, owner: nil, group: nil, **)
    check_path(path)
    mkdir(File.dirname(path), **)
    run("tee -- #{path}", capture: true, stdin_data: data, **)
    chmod(path, mode) if mode
    chown(path, owner, group) if owner || group
  end

  def file_append(path, data, mode: nil, owner: nil, group: nil, **)
    check_path(path)
    mkdir(File.dirname(path), **)
    run("tee -a -- #{path}", capture: true, stdin_data: data, **)
    chmod(path, mode) if mode
    chown(path, owner, group) if owner || group
  end

  def mkdir(path, mode: nil, owner: nil, group: nil, **)
    check_path(path)
    run("mkdir -p -- #{path}", **)
    chmod(path, mode) if mode
    chown(path, owner, group) if owner || group
  end

  def chmod(path, mode, **)
    check_path(path)
    check_mode(mode)

    mode = format("%04o", mode) if mode.is_a?(Integer)

    run("chmod #{mode} -- #{path}", **)
  end

  def chown(path, owner = nil, group = nil, **)
    check_path(path)
    check_id_or_name(owner)
    check_id_or_name(group)

    owner_group = +""
    owner_group << owner.to_s if owner
    owner_group << ":#{group}" if group
    return if owner_group.empty?

    run("chown #{owner_group} -- #{path}", **)
  end

  def whoami
    run("whoami", capture: true).chomp
  end

  def pkg_mgr
    @pkg_mgr ||=
      ["apt", "dnf", "yum", "pacman", "apk", "zypper"].find do |mgr|
        run("which #{mgr}", capture: true, exception: false, stderr: nil)&.chomp&.length&.positive?
      end
  end

  def users
    file_read("/etc/passwd", user: "root").each_line.map { |line| line.split(":").first }
  end

  def groups
    file_read("/etc/group", user: "root").each_line.map { |line| line.split(":").first }
  end

  def installed?
    !info.nil?
  end

  def info(force: false)
    WSL.clear if force
    WSL.dict[@distro]
  end

  def version
    info[:version]
  end

  def key
    info[:key]
  end

  def uid
    info[:uid]
  end

  def uid=(uid)
    registry(mode: "w") do |reg|
      reg["DefaultUid"] = uid
    end
    info[:uid] = uid
  end

  def oobe
    info[:oobe]
  end
  alias_method :oobe?, :oobe

  def oobe=(oobe)
    registry(mode: "w") do |reg|
      reg["RunOOBE"] = (oobe ? 1 : 0)
    end
    info[:oobe] = oobe
  end

  def registry(**, &)
    WSL.open_lxss_registry(key, **, &)
  end

  # wsl run helper methods
  private def check_path(path)
    return if path =~ %r{\A[\w/.-]+\z}

    raise "invalid path: #{path}"
  end

  private def check_mode(mode)
    case mode
    when Integer
      return if mode.between?(0, 0o7777)
    when String
      return if mode =~ /\A([augo]*([-+=][rstwxXugo])+(,[augo]*([-+=][rstwxXugo])+)|[0-7]{3,4})\z/
    end

    raise "invalid mode: #{mode}"
  end

  private def check_id_or_name(id_or_name)
    case id_or_name
    when nil
      return
    when Integer
      return if id_or_name >= 0
    when String
      return if id_or_name =~ /\A\w+\z/
    end

    raise "invalid id or name: #{id_or_name}"
  end

  # rubocop: disable Naming/MethodParameterName
  private def generate_wsl_cmd(cmd, distro: @distro, user: @user, cd: @cd, env: @env)
    wsl_cmd = +"wsl"
    wsl_cmd << "  -d #{distro}" if distro
    wsl_cmd << " -u #{user}" if user
    wsl_cmd << " --cd \"#{cd}\"" if cd
    wsl_cmd << " --shell-type login" if user != "root"
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
      @dict = nil
    end

    def status(force: false)
      @status = nil if force
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

    def dict(force: false)
      @dict = nil if force
      return @dict if @dict

      @dict = {}
      [wsl_list, registry_list].each do |list|
        list.each do |info|
          @dict[info[:name]] ||= {}
          @dict[info[:name]].merge!(info)
        end
      end
      @dict
    end

    def list(...)
      dict(...).values
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
          {
            default: m[1] == "*",
            name: m[2],
            state: m[3],
            version: m[4].to_i,
          }
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
            list << {
              name: sub["DistributionName"],
              key: key,
              uid: sub["DefaultUid"],
              path: sub["BasePath"],
              oobe: sub["RunOOBE"].positive?,
            }
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

    private def calc_mask(mode)
      desired = 0
      desired |= Win32::Registry::KEY_READ if mode.include?("r")
      desired |= Win32::Registry::KEY_WRITE if mode.include?("w")
      desired |= Win32::Registry::KEY_EXECUTE if mode.include?("x")
      desired
    end
  end
end

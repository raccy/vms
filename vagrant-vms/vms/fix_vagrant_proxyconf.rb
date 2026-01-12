# patch for vagrant-proxyconf to support yum proxy configuration
# see https://github.com/tmatilai/vagrant-proxyconf/pull/243
require "vagrant-proxyconf/action/configure_yum_proxy"
module VagrantPlugins
  module ProxyConf
    class Action
      class ConfigureYumProxy < Base
        private

        def configure_machine
          return if !supported?

          tmp = "/tmp/vagrant-proxyconf"
          path = config_path

          @machine.communicate.tap do |comm|
            comm.sudo("rm -f #{tmp}", error_check: false)
            comm.upload(ProxyConf.resource("yum_config.awk"), tmp)
            comm.sudo("touch #{path}")
            comm.sudo("gawk -i inplace -f #{tmp} #{proxy_params} `realpath #{path}`")
            comm.sudo("rm -f #{tmp}")
          end

          true
        end

        def unconfigure_machine
          return if !supported?

          @machine.communicate.tap do |comm|
            if comm.test("grep '^proxy' #{config_path}")
              comm.sudo("sed -i.bak -e '/^proxy/d' `realpath #{config_path}`")
            end
          end

          true
        end
      end
    end
  end
end

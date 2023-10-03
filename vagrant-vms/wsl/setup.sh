#!/bin/bash

# Setup Ansible and Vagrant

if [ "$(sudo whoami)" != "root" ]; then
  echo no root
  exit 1
fi

http_proxy=$(/mnt/c/Windows/System32/cmd.exe /C "ECHO %http_proxy%" | sed 's/\s*$//')
https_proxy=$(/mnt/c/Windows/System32/cmd.exe /C "ECHO %https_proxy%" | sed 's/\s*$//')
ftp_proxy=$(/mnt/c/Windows/System32/cmd.exe /C "ECHO %ftp_proxy%" | sed 's/\s*$//')
no_proxy=$(/mnt/c/Windows/System32/cmd.exe /C "ECHO %no_proxy%" | sed 's/\s*$//')

[ -n "$http_proxy"  ] && export http_proxy
[ -n "$https_proxy" ] && export https_proxy
[ -n "$ftp_proxy"   ] && export ftp_proxy
[ -n "$no_proxy"    ] && export no_proxy

if [ -n "$https_proxy" ]; then
  grep proxy /etc/dnf/dnf.conf > /dev/null
  if [ $? -ne 0 ]; then
    sudo bash -c "echo 'proxy=${https_proxy}' >> /etc/dnf/dnf.conf"
  fi

  grep timeout /etc/dnf/dnf.conf > /dev/null
  if [ $? -ne 0 ]; then
    sudo bash -c "echo 'timeout=600' >> /etc/dnf/dnf.conf"
  fi

  if [ ! -e /etc/profile.d/proxy.sh ]; then
    sudo bash -c "echo '# proxy env' > /etc/profile.d/proxy.sh"
    [ -n "$http_proxy"  ] && sudo bash -c "echo export http_proxy=${http_proxy} >> /etc/profile.d/proxy.sh"
    [ -n "$https_proxy" ] && sudo bash -c "echo export https_proxy=${https_proxy} >> /etc/profile.d/proxy.sh"
    [ -n "$ftp_proxy"   ] && sudo bash -c "echo export ftp_proxy=${ftp_proxy} >> /etc/profile.d/proxy.sh"
    [ -n "$no_proxy"    ] && sudo bash -c "echo export no_proxy=${no_proxy} >> /etc/profile.d/proxy.sh"
  fi
fi

sudo dnf -y check-update
sudo dnf -y update

# Ansible
sudo dnf -y install python3 python3-pip
python3 -m pip install --user ansible

# Vagrant

if [ -z "$(sudo dnf repolist hashicorp)" ]; then
  sudo dnf -y install yum-utils
  sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
fi
sudo dnf -y install vagrant

export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS=1
grep VAGRANT_WSL_ENABLE_WINDOWS_ACCESS ~/.bashrc > /dev/null
if [ $? -ne 0 ]; then
  echo 'export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS=1' >> ~/.bashrc
fi

vagrant_home_win_path=$(/mnt/c/Windows/System32/cmd.exe /C "ECHO %VAGRANT_HOME%" | sed 's/\s*$//')
if [ -n "$vagrant_home_win_path" ]; then
  vagrant_home_path=$(wslpath -u "${vagrant_home_win_path}")
  export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="${vagrant_home_path}"
  grep VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH ~/.bashrc > /dev/null
  if [ $? -ne 0 ]; then
      echo "export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH=\"${vagrant_home_path}\"" >> ~/.bashrc
    fi
fi

vagrant plugin install vagrant-proxyconf vagrant-timezone vagrant-vbguest

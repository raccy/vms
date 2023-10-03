#!/bin/bash

# Setup Ansible and Vagrant

if [ "$(sudo whoami)" != "root" ]; then
  echo no root
  exit 1
fi

if [ ! -e /etc/wsl.conf ]; then
  sudo tee /etc/wsl.conf << EOF
[automount]
options = "metadata"
[network]
hostname = vms
EOF
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
  grep proxy /etc/dnf/dnf.conf > /dev/null   || echo proxy=${https_proxy} | sudo tee -a /etc/dnf/dnf.conf
  grep timeout /etc/dnf/dnf.conf > /dev/null || echo timeout=600          | sudo tee -a /etc/dnf/dnf.conf

  if [ ! -e /etc/profile.d/proxy.sh ]; then
    echo '# proxy env' | sudo tee /etc/profile.d/proxy.sh
    [ -n "$http_proxy"  ] && echo export http_proxy=${http_proxy}   | sudo tee -a /etc/profile.d/proxy.sh
    [ -n "$https_proxy" ] && echo export https_proxy=${https_proxy} | sudo tee -a /etc/profile.d/proxy.sh
    [ -n "$ftp_proxy"   ] && echo export ftp_proxy=${ftp_proxy}     | sudo tee -a /etc/profile.d/proxy.sh
    [ -n "$no_proxy"    ] && echo export no_proxy=${no_proxy}       | sudo tee -a /etc/profile.d/proxy.sh
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
grep VAGRANT_WSL_ENABLE_WINDOWS_ACCESS ~/.bashrc || echo 'export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS=1' >> ~/.bashrc

vagrant_home_win_path=$(/mnt/c/Windows/System32/cmd.exe /C "ECHO %VAGRANT_HOME%" | sed 's/\s*$//')
if [ -n "$vagrant_home_win_path" ]; then
  vagrant_home_path=$(dirname `wslpath -u "${vagrant_home_win_path}"`)
  export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="${vagrant_home_path}"
  grep VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH ~/.bashrc \
    || echo "export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH=\"${vagrant_home_path}\"" >> ~/.bashrc
fi

# vagrant plugin install vagrant-proxyconf vagrant-timezone vagrant-vbguest

# Git

sudo dnf -y install git
git_user_name=$("/mnt/c/Program Files/Git/bin/git.exe" config --get user.name | sed 's/\s*$//')
git_user_email=$("/mnt/c/Program Files/Git/bin/git.exe" config --get user.email | sed 's/\s*$//')
git_pull_rebase=$("/mnt/c/Program Files/Git/bin/git.exe" config --get pull.rebase | sed 's/\s*$//')

git config --global --get user.name   || git config --global --add user.name "$git_user_name"
git config --global --get user.email  || git config --global --add user.email "$git_user_email"
git config --global --get pull.rebase || git config --global --add pull.rebase "$git_pull_rebase"

# Ruby

sudo dnf -y install ruby

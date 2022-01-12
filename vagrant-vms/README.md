# vagrant-vms
vagrantのvm集

WSL上のvagrantを使うことを前提に、Win側と連携するように工夫する予定。

## WSLでの設定

metadataは有効にする。
appendWindowsPathは無効でもよい。

```/etc/wsl.conf
[automount]
options = "metadata"
[interop]
appendWindowsPath = false
```

https://www.vagrantup.com/docs/other/wsl

[[interrop]](https://docs.microsoft.com/en-us/windows/wsl/wsl-config#interop-settings)で`appendWindowsPath`が有効の場合は"/mnt/c/Program Files/Oracle/VirtualBox"のみ追加でよい。

```.bashrc
export PATH="$PATH:/mnt/c/WINDOWS/system32:/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0:/mnt/c/Apps/HashiCorp/Vagrant/bin:/mnt/c/Program Files/Oracle/VirtualBox"
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
```

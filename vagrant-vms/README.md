# vagrant-vms
vagrantのvm集

WSL上のvagrantを使うことを前提に、Win側と連携するように工夫する予定。

## Issues

- [ ] snapのrubyでは問題が起きるので、Ubuntuはrbenvにするしかないと思われる。

## vagrant plugin

プラグインは必要であれば。

```
vagrant plugin install vagrant-vbguest
vagrant plugin install vagrant-proxyconf
```

## WSL2での設定

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

WSL2では`virtualbox_WSL2`が必要。

```
vagrant plugin install virtualbox_WSL2
```

ファイアウォールはパブリックについても許可しておくこと。

## その他のメモ

generic/rocky8のVirtualBoxについて`PIT: mode=2 ...`から`PIT: mode=0 ...`に切り替わるのに数分かかる場合がある。原因は不明。

boxの違い

- generic: vboxでは遅いときがある。hyper-vあり。SE Linuxは`enforecing`。
- eurolinux-vagrant: SE Linuxは`permissive`。
- boxomatic: SE Linuxが`disabled`。

下は書きかけ

|accont   |R8 |R9 |U20|U22|CS9|SEL|
|---------|---|---|---|---|---|---|
|generic  |〇 |✕ |〇 |✕ |✕ |e  |
|eurolinux|
|boxomatic|
|centos   |
|ubuntu   |
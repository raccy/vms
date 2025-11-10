# WSL環境セットアップ for vagrant

vagrantが実行できるWSLをインストールする。

オリジナルは https://github.com/raccy/wsl_setup になる。

## 動作環境

- Windows 11 25H2 以上
- Ruby 3.3 以上 (Ruby Installerでインストール済み)

タスクはRakefileで書かれているため、Rubyが必要です。

## 実行方法

1. Rubyをインストールしておく。
2. rake を実行する。

## Rake

- (default) ... createを実行する。
- create ... WSLシステムをインストールし、カレントディレクトリにLinuxを置く。
- update ... アップデートする。
- destory ... Linuxを削除する。

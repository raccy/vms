# nginx-local ロール

nginxをコンパイルにlocalにインストールするAnsibleのロール

## 提供するサービス

- nginx
    - modmesucrity
    - ngx_mruby


## テスト済み環境

- Rocxy Linux 9

## 設定の注意事項

- logrotate
    - "/usr"配下は保護されているため、ログの所の解除が必要になる。
    - サービスリスタートでないとmodsecのログは読み直されない。
- ログ
    - ログユーザーがいる場合はnginxグループも見えるようにしておく。

# 拡張スキーマ

OpenLDAP標準以外のスキーマを記載する。

## Samba スキーマ

- ファイル名: samba.schema
- 入手URL: https://github.com/samba-team/samba/tree/master/examples/LDAP/samba.schema
    sambaパッケージにある/usr/share/doc/samba/LDAP/samba.schemaと同じファイルになる。同じディレクトリのsamba.ldifは古い。
- 説明: Samba用属性の拡張スキーマ

## eduPerson スキーマ

- ファイル名: eduperson.schema
- 入手元: https://github.com/REFEDS/eduperson/tree/master/schema/openldap
    ldifの方が新しい。
- 説明: ShibbolethにeduPersonに関する属性の拡張スキーマ

## 学認 スキーマ

- ファイル名: gakunin.schema
- 入手元: https://meatwiki.nii.ac.jp/confluence/download/attachments/12158166/gakunin.schema?version=3&modificationDate=1497257194000&api=v2
- 説明: 学認で使用される属性の拡張スキーマ

## Postfix スキーマ

- ファイル名: postifx.schema
- 入手元: http://www.ldapadmin.org/docs/introduction.html
- 説明: Postfixのマップなどで使用できるLDAP Adminの拡張スキーマ

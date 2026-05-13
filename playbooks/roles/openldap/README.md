# OpenLDAP

設定ファイルなど

```
openldap_pkg:
  dnf:
    run_dir: /run/openldap
    config_dir: /etc/openldap
    module_dir: /usr/lib64/openldap
    database_dir: /var/lib/ldap
    user: ldap
    group: ldap
  apt:
    run_dir: /var/run/slapd
    config_dir: /etc/ldap
    module_dir: /usr/lib/ldap
    database_dir: /var/lib/ldap
    user: openldap
    group: openldap
```

back_monitorの有無

組み込み済みのモジュールを指定しても単純に無視される。



## rocky8

accesslog.la
allop.la
auditlog.la
back_dnssrv.la
back_ldap.la
back_meta.la
back_null.la
back_passwd.la
back_perl.la
back_relay.la
back_shell.la
back_sock.la
collect.la
constraint.la
dds.la
deref.la
dyngroup.la
dynlist.la
memberof.la
pcache.la
ppolicy.la
refint.la
retcode.la
rwm.la
seqmod.la
smbk5pwd.la
sssvlv.la
syncprov.la
translucent.la
unique.la
valsort.la


## rocky9

accesslog.la
allop.la
auditlog.la
autoca.la
back_asyncmeta.la
back_dnssrv.la
back_ldap.la
back_meta.la
back_null.la
back_passwd.la
back_relay.la
back_sock.la
collect.la
constraint.la
dds.la
deref.la
dyngroup.la
dynlist.la
homedir.la
lloadd.la
memberof.la
otp.la
pcache.la
ppolicy.la
refint.la
remoteauth.la
retcode.la
rwm.la
seqmod.la
smbk5pwd.la
sssvlv.la
syncprov.la
translucent.la
unique.la
valsort.la

## Ubuntu 20.04

accesslog.la
auditlog.la
autogroup.la
back_bdb.la
back_dnssrv.la
back_hdb.la
back_ldap.la
back_mdb.la
back_meta.la
back_monitor.la
back_null.la
back_passwd.la
back_perl.la
back_relay.la
back_shell.la
back_sock.la
back_sql.la
collect.la
constraint.la
dds.la
deref.la
dyngroup.la
dynlist.la
lastbind.la
memberof.la
nssov.la
pcache.la
ppolicy.la
pw-sha2.la
refint.la
retcode.la
rwm.la
seqmod.la
sssvlv.la
syncprov.la
translucent.la
unique.la
valsort.la

## Ubuntu 22.04

accesslog.la
argon2.la
auditlog.la
autogroup.la
back_asyncmeta.la
back_dnssrv.la
back_ldap.la
back_mdb.la
back_meta.la
back_null.la
back_passwd.la
back_perl.la
back_relay.la
back_sock.la
back_sql.la
collect.la
constraint.la
dds.la
deref.la
dyngroup.la
dynlist.la
homedir.la
lastbind.la
memberof.la
otp.la
pcache.la
ppolicy.la
pw-sha2.la
refint.la
remoteauth.la
retcode.la
rwm.la
seqmod.la
sssvlv.la
syncprov.la
translucent.la
unique.la
valsort.la
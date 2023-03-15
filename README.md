# openldap-openshift

File 'ldap.properties' references ldif file

1. Update file 'ldap.properties'
2. Update file 'custom_persons.ldif'
3. Run add-ldap.sh -p ./ldap.properties

## TBD

1. verify access token, service account, other minors

## Pak Configuration

```
name: customdomain1

type: Custom

DN: dc=customdomain1,dc=org

BIND: cn=admin,dc=customdomain1,dc=org

Password: passw0rd

URL ldap://customdomain1-ldap.test-ldap1.svc.cluster.local:389

Group filter          (&(cn=%v)(objectclass=groupOfNames))
User filter           (&(uid=%v)(objectclass=person))
Group ID map          *:cn
User ID map           *:uid
Group member ID map   groupOfNames:member
```

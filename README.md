# openldap-openshift


## Add an LDAP service
File 'ldap.properties' references ldif file

1. Update file 'ldap.properties'
2. Update file 'custom_persons.ldif'
3. Run ./add-ldap.sh -p ./ldap.properties



## Add an IDP configuration (Pak Configuration)
File 'idp.properties' references an LDAP service

1. Update file ./idp.properties
2. Run ./add-idp.sh -p ./idp.properties

## Examples

### OpenLDAP parameters
```
Connection name: vuxdomain1
Server type: Custom
  LDAP authentication

Set the parameters for authenticating with your LDAP server.
Base DN: dc=vuxdomain,dc=org
Bind DN: cn=admin,dc=vuxdomain,dc=org
Bind DN password: passw0rd
LDAP server
URL: ldap://vuxdomain-ldap.a-vux-cfg1.svc.cluster.local:389

Filters

LDAP filters are configured by default. Enter any custom filters that you require.
Group filter:         (&(cn=%v)(|(objectclass=groupOfNames)(objectclass=groupOfUniqueNames)(objectclass=groupOfURLs)))
User filter:          (&(cn=%v)(objectclass=person))
Group ID map:         *:cn
User ID map:          *:uid
Group member ID map:  memberof:member
```

### IDP parameters
Parameters used to configure a Pak IDP are values from LDAP configuration plus IDP name.

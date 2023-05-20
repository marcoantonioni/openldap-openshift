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

Note: reboot BAW pods to get LDAP groups visibles (e.g. ProcessAdmin -> Group Management) 

## Examples

```
# cfg1
./add-ldap.sh -p vux-cfg1.properties
./add-phpadmin.sh -p ./vux-cfg1.properties -n cp4ba
./add-idp.sh -p ./idp1.properties

# cfg2
./add-ldap.sh -p vux-cfg2.properties
./add-phpadmin.sh -p ./vux-cfg2.properties -n cp4ba
./add-idp.sh -p ./idp2.properties

```

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

## Examples

### Set hostname and token

Set CP4BA namespace
```
TNS=cp4ba
```

Get IAM token
```
iamadmin=$(oc get secret -n ${TNS} platform-auth-idp-credentials -o jsonpath='{.data.admin_username}' | base64 -d)
iampass=$(oc get secret -n ${TNS} platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d)
echo $iamadmin $iampass
```

Get IAM token
```
iamhost=https://$(oc get route -n ${TNS} cp-console -o jsonpath="{.spec.host}")
iamaccesstoken=$(curl -sk -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" -d "grant_type=password&username=$iamadmin&password=$iampass&scope=openid" $iamhost/idprovider/v1/auth/identitytoken | jq -r .access_token)

echo $iamhost
echo $iamaccesstoken
```


### list of LDAP configurations
```
curl -sk -X GET --header "Authorization: Bearer $iamaccesstoken" --header "Content-Type: application/json" ${iamhost}/idmgmt/identity/api/v1/directory/ldap/list | jq .
```

### LDAP configuration
```
LID=2a64ba20-f570-11ed-b7de-df2c225867da
curl -sk -X GET --header "Authorization: Bearer $iamaccesstoken" --header "Content-Type: application/json" ${iamhost}/idmgmt/identity/api/v1/directory/ldap/${LID} | jq .
```

### Update LDAP configuration
```
LID=2a64ba20-f570-11ed-b7de-df2c225867da
curl -sk -X PUT --header "Authorization: Bearer $iamaccesstoken" --header "Content-Type: application/json" ${iamhost}/idmgmt/identity/api/v1/directory/ldap/${LID} \
  -d '{
    "LDAP_ID": "vuxdomain",
    "LDAP_REALM": "REALM",
    "LDAP_HOST": "vuxdomain-ldap.a-vux-cfg1.svc.cluster.local",
    "LDAP_PORT": "389",
    "LDAP_IGNORECASE": "true",
    "LDAP_BASEDN": "dc=vuxdomain,dc=net",
    "LDAP_BINDDN": "cn=admin,dc=vuxdomain,dc=net",
    "LDAP_TYPE": "Custom",
    "LDAP_USERFILTER": "(&(cn=%v)(objectclass=person))",
    "LDAP_GROUPFILTER": "(&(cn=%v)(|(objectclass=groupOfNames)(objectclass=groupOfUniqueNames)(objectclass=groupOfURLs)))",
    "LDAP_USERIDMAP": "*:uid",
    "LDAP_GROUPIDMAP": "*:cn",
    "LDAP_GROUPMEMBERIDMAP": "memberof:member",
    "LDAP_URL": "ldap://vuxdomain-ldap.a-vux-cfg1.svc.cluster.local:389",
    "LDAP_PROTOCOL": "ldap",
    "LDAP_NESTEDSEARCH": "false",
    "LDAP_PAGINGSEARCH": "false"
  }' | jq .
```

### Update LDAP configuration with LDAP_GROUP_SEARCHBASE_LIST
```
LID=2a64ba20-f570-11ed-b7de-df2c225867da
curl -sk -X PUT --header "Authorization: Bearer $iamaccesstoken" --header "Content-Type: application/json" ${iamhost}/idmgmt/identity/api/v1/directory/ldap/${LID} \
  -d '{
    "LDAP_ID": "vuxdomain",
    "LDAP_REALM": "REALM",
    "LDAP_HOST": "vuxdomain-ldap.a-vux-cfg1.svc.cluster.local",
    "LDAP_PORT": "389",
    "LDAP_IGNORECASE": "true",
    "LDAP_BASEDN": "dc=vuxdomain,dc=net",
    "LDAP_BINDDN": "cn=admin,dc=vuxdomain,dc=net",
    "LDAP_TYPE": "Custom",
    "LDAP_USERFILTER": "(&(cn=%v)(objectclass=person))",
    "LDAP_GROUPFILTER": "(&(cn=%v)(|(objectclass=groupOfNames)(objectclass=groupOfUniqueNames)(objectclass=groupOfURLs)))",
    "LDAP_USERIDMAP": "*:uid",
    "LDAP_GROUPIDMAP": "*:cn",
    "LDAP_GROUPMEMBERIDMAP": "memberof:member",
    "LDAP_URL": "ldap://vuxdomain-ldap.a-vux-cfg1.svc.cluster.local:389",
    "LDAP_PROTOCOL": "ldap",
    "LDAP_NESTEDSEARCH": "false",
    "LDAP_GROUP_SEARCHBASE_LIST": [
      "['dc=vuxdomain,dc=net']"
    ],
    "LDAP_PAGINGSEARCH": "false"
  }' | jq .
```

### For more examples and details

https://www.ibm.com/docs/en/cloud-paks/1.0?topic=apis-directory-management

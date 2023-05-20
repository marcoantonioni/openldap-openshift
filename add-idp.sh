#!/bin/bash

#-------------------------------
# read installation parameters
PROPS_FILE="./idp.properties"

CHECK_PARAMS=false
while getopts p:c flag
do
    case "${flag}" in
        c) CHECK_PARAMS=true;;
        p) PROPS_FILE=${OPTARG};;
    esac
done

if [[ -z ${PROPS_FILE}"" ]];
then
    # load default props file
    PROPS_FILE="./idp.properties"
    echo "Sourcing default properties file "
    source ${PROPS_FILE}
else
    if [[ -f ${PROPS_FILE} ]];
    then
        echo "Sourcing properties file "${PROPS_FILE}
        source ${PROPS_FILE}
    else
        echo "ERROR: Properties file "${PROPS_FILE}" not found !!!"
        exit
    fi
fi


#-------------------------------
createIdp () {

# "LDAP_GROUP_SEARCHBASE_LIST": ["'${LDAP_GROUP_SEARCHBASE_LIST}'"],  

echo '{ 
  "LDAP_ID": "'${IDP_NAME}'", 
  "LDAP_URL": "'${LDAP_URL}'", 
  "LDAP_IGNORECASE": "true",
  "LDAP_BASEDN": "'${LDAP_BASEDN}'", 
  "LDAP_BINDDN": "'${LDAP_BINDDN}'",  
  "LDAP_BINDPASSWORD": "'${LDAP_BINDPASSWORD}'", 
  "LDAP_TYPE": "'${LDAP_TYPE}'", 
  "LDAP_USERFILTER": "'${LDAP_USERFILTER}'", 
  "LDAP_GROUPFILTER": "'${LDAP_GROUPFILTER}'", 
  "LDAP_USERIDMAP": "'${LDAP_USERIDMAP}'", 
  "LDAP_GROUPIDMAP": "'${LDAP_GROUPIDMAP}'", 
  "LDAP_GROUPMEMBERIDMAP": "'${LDAP_GROUPMEMBERIDMAP}'",
  "LDAP_NESTEDSEARCH": "'${LDAP_NESTEDSEARCH}'",
  "LDAP_PAGINGSEARCH": "'${LDAP_PAGINGSEARCH}'",
  "LDAP_PAGING_SIZE": "'${LDAP_PAGING_SIZE}'" 
}' > ./${IDP_NAME}.json

ADMIN_NAME=admin
ADMIN_PASSW=$(oc get secret platform-auth-idp-credentials -n ${TNS} -o jsonpath='{.data.admin_password}' | base64 -d)
CONSOLE_HOST=https://$(oc get route -n ${TNS} cp-console -o jsonpath="{.spec.host}")
IAM_ACCESS_TK=$(curl -sk -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
    -d "grant_type=password&username=${ADMIN_NAME}&password=${ADMIN_PASSW}&scope=openid" \
    ${CONSOLE_HOST}/idprovider/v1/auth/identitytoken | jq -r .access_token)

RESPONSE=$(curl -sk -X POST "${CONSOLE_HOST}/idmgmt/identity/api/v1/directory/ldap/onboardDirectory" \
            -H "Authorization: Bearer ${IAM_ACCESS_TK}" -H 'Content-Type: application/json' -d @./${IDP_NAME}.json | jq .)
if [[ "${RESPONSE}" == *"error"* ]]; then
  echo -e "ERROR configuring [${IDP_NAME}]\n${RESPONSE}"
else
  echo "IDP [${IDP_NAME}] configured, id [${RESPONSE}]"
  echo "Pak admin / ${ADMIN_PASSW}"
fi

}

#-------------------------------

echo "Configuring IDP ["${IDP_NAME}"]"

createIdp


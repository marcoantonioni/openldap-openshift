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
listIdp () {

ADMIN_PASSW=$(oc get secret platform-auth-idp-credentials -n ${TNS} -o jsonpath='{.data.admin_password}' | base64 -d)
CONSOLE_HOST=https://$(oc get route -n ${TNS} cp-console -o jsonpath="{.spec.host}")
IAM_ACCESS_TK=$(curl -sk -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
    -d "grant_type=password&username=${ADMIN_NAME}&password=${ADMIN_PASSW}&scope=openid" \
    ${CONSOLE_HOST}/idprovider/v1/auth/identitytoken | jq -r .access_token)

# lista IDP
echo ""
echo "IDP items:"
curl -sk -X GET "${CONSOLE_HOST}/idprovider/v3/auth/idsource" -H "Authorization: Bearer ${IAM_ACCESS_TK}" | jq .

}

#-------------------------------

#-------------------------------

echo "List of IDPs"

listIdp

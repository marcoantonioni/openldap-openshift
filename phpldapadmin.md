# PHPADMIN for OpenLDAP in CP4BA

Install php-admin web console to admin openldap server

## List available tags for phpldapadmin image
```
podman login -u cp -p ${CP4BA_AUTO_ENTITLEMENT_KEY} cp.icr.io
skopeo list-tags docker://cp.icr.io/cp/cp4a/demo/phpldapadmin
```

## Use certs from CP4BA install or use your own

```
# root ca
oc get secrets -n cp4ba icp4adeploy-root-ca -o jsonpath='{.data.tls\.crt}' | base64 -d > ./certs/tls.cert
oc get secrets -n cp4ba icp4adeploy-root-ca -o jsonpath='{.data.tls\.key}' | base64 -d > ./certs/tls.key

# prereq ext
oc get secrets -n cp4ba icp4adeploy-prereq-ext-tls-secret -o jsonpath='{.data.tls\.crt}' | base64 -d > ./certs/tls-prereq-ext.cert
oc get secrets -n cp4ba icp4adeploy-prereq-ext-tls-secret -o jsonpath='{.data.tls\.key}' | base64 -d > ./certs/tls-prereq-ext.key
```

## Installation steps
```
source ./ldap1.properties

#-------------------------------------
# Create Secrets from CRT/KEY (must have sertificates in ./certs folder)
oc create secret -n ${TNS} tls phpadminldap-root-ca --cert=./certs/tls.cert --key=./certs/tls.key
oc create secret -n ${TNS} tls phpadminldap-prereq-ext --cert=./certs/tls-prereq-ext.cert --key=./certs/tls-prereq-ext.key

#-------------------------------------
# set image name and tag
PHPLDAPADMIN_IMAGE="cp.icr.io/cp/cp4a/demo/phpldapadmin"
PHPLDAPADMIN_TAG="0.9.0.1"

#-------------------------------------
# 
cat <<EOF | oc apply -n ${TNS} -f -
kind: ConfigMap
apiVersion: v1
metadata:
  name: php-admin-cm
  namespace: ${TNS}
  labels:
    app: phpldapadmin
    chart: phpldapadmin-0.1.3
    heritage: Tiller
    release: phpldapadmin
data:
  PHPLDAPADMIN_HTTPS: 'true'
  PHPLDAPADMIN_HTTPS_CA_CRT_FILENAME: ca.crt
  PHPLDAPADMIN_HTTPS_CRT_FILENAME: tls.crt
  PHPLDAPADMIN_HTTPS_KEY_FILENAME: tls.key
  PHPLDAPADMIN_LDAP_HOSTS: ${LDAP_DOMAIN}-ldap
EOF

#-------------------------------------
# 
cat <<EOF | oc apply -n ${TNS} -f -
kind: Deployment
apiVersion: apps/v1
metadata:
  name: phpldapadmin
  namespace: ${TNS}
  labels:
    app: phpldapadmin
    chart: phpldapadmin-0.1.3
    heritage: Tiller
    release: phpldapadmin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: phpldapadmin
      release: phpldapadmin
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: phpldapadmin
        release: phpldapadmin
    spec:
      restartPolicy: Always
      initContainers:
        - name: phpldapadmin-init-certs
          image: '${PHPLDAPADMIN_IMAGE}:${PHPLDAPADMIN_TAG}'
          command:
            - /bin/sh
            - '-ec'
            - |
              cp /rootca/tls.crt /certs/ca.crt
              cp /tlssecret/* /certs
          resources:
            limits:
              cpu: 100m
              memory: 128Mi
            requests:
              cpu: 100m
              memory: 128Mi
          volumeMounts:
            - name: phpldapadmin-certs
              mountPath: /certs
            - name: rootcasecret
              mountPath: /rootca
            - name: tlssecret
              mountPath: /tlssecret
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          imagePullPolicy: IfNotPresent
      serviceAccountName: ibm-cp4ba-anyuid
      terminationGracePeriodSeconds: 30
      securityContext: {}
      containers:
        - resources:
            limits:
              cpu: 500m
              memory: 512Mi
            requests:
              cpu: 100m
              memory: 256Mi
          terminationMessagePath: /dev/termination-log
          name: phpldapadmin
          ports:
            - name: https-port
              containerPort: 443
              protocol: TCP
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - name: phpldapadmin-certs
              mountPath: /container/service/phpldapadmin/assets/apache2/certs
          terminationMessagePolicy: File
          envFrom:
            - configMapRef:
                name: php-admin-cm
          image: '${PHPLDAPADMIN_IMAGE}:${PHPLDAPADMIN_TAG}'
          args:
            - '--copy-service'
      serviceAccount: ibm-cp4ba-anyuid
      volumes:
        - name: phpldapadmin-certs
          emptyDir: {}
        - name: rootcasecret
          secret:
            secretName: phpadminldap-root-ca
            defaultMode: 420
        - name: tlssecret
          secret:
            secretName: phpadminldap-prereq-ext
            defaultMode: 420
      dnsPolicy: ClusterFirst
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 600
EOF

#-------------------------------------
# 
cat <<EOF | oc apply -n ${TNS} -f -
apiVersion: v1
kind: Service
metadata:
  name: php-admin
  namespace: ${TNS}
spec:
  selector:
    app: phpldapadmin
  ports:
    - protocol: TCP
      port: 443
      targetPort: 443
EOF

# create temp route
oc expose service -n ${TNS} php-admin

#-------------------------------------
# Build php-admin route
URL=$(oc get route -n ${TNS} php-admin -o jsonpath='{.spec.host}')
readarray -d . -t URLARR <<< "$URL"
PARTS=""
for (( n=0; n < ${#URLARR[*]}; n++))
do
  if [[ $n -eq 0 ]]; then
    PARTS="php-admin-"${TNS}
  else
    PARTS=$PARTS".${URLARR[n]}"
  fi 
done

export PHP_FQDN=$PARTS
echo "php-admin host: "${PHP_FQDN}

# delete temp route
oc delete route -n ${TNS} php-admin

#-------------------------------------
# 
cat <<EOF | oc apply -n ${TNS} -f -
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: php-admin
  namespace: ${TNS}
spec:
  host: >-
    ${PHP_FQDN}
  to:
    kind: Service
    name: php-admin
    weight: 100
  port:
    targetPort: 443
  tls:
    termination: passthrough
    insecureEdgeTerminationPolicy: None
  wildcardPolicy: None
EOF

#-----------------------------------------
# php-admin access credentials

PHPADMIN_USER="cn=admin,dc=${LDAP_DOMAIN},dc=org"
PHPADMIN_PASSWORD=$(oc -n ${TNS} get secret ${LDAP_DOMAIN}-secret -o jsonpath='{.data.LDAP_ADMIN_PASSWORD}' | base64 -d)

echo "php-amin user[${PHPADMIN_USER}] password[${PHPADMIN_PASSWORD}]"
```

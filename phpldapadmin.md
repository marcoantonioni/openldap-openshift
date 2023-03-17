# PHPADMIN - OpenLDAP

To be refined...

```
export CP4BA_AUTO_NAMESPACE="cp4ba"

URL=$(oc get route cpd -n ${CP4BA_AUTO_NAMESPACE} -o jsonpath='{.spec.host}')
readarray -d . -t URLARR <<< "$URL"
PARTS=""
for (( n=0; n < ${#URLARR[*]}; n++))
do
  if [[ $n -eq 0 ]]; then
    PARTS="php-admin"
  else
    PARTS=$PARTS".${URLARR[n]}"
  fi 
done

# "https://"
export PHP_FQDN=$PARTS

cat <<EOF | oc apply -n ${CP4BA_AUTO_NAMESPACE} -f -
kind: ConfigMap
apiVersion: v1
metadata:
  name: php-admin-cm
  namespace: ${CP4BA_AUTO_NAMESPACE}
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
  PHPLDAPADMIN_LDAP_HOSTS: icp4adeploy-ldap-service
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: icp4adeploy-phpldapadmin
  namespace: ${CP4BA_AUTO_NAMESPACE}
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
          image: 'cp.icr.io/cp/cp4a/demo/phpldapadmin:0.9.0.1'
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
          image: 'cp.icr.io/cp/cp4a/demo/phpldapadmin:0.9.0.1'
          args:
            - '--copy-service'
      serviceAccount: ibm-cp4ba-anyuid
      volumes:
        - name: phpldapadmin-certs
          emptyDir: {}
        - name: rootcasecret
          secret:
            secretName: icp4adeploy-root-ca
            defaultMode: 420
        - name: tlssecret
          secret:
            secretName: icp4adeploy-prereq-ext-tls-secret
            defaultMode: 420
      dnsPolicy: ClusterFirst
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 600
---
apiVersion: v1
kind: Service
metadata:
  name: php-admin
  namespace: ${CP4BA_AUTO_NAMESPACE}
spec:
  selector:
    app: phpldapadmin
  ports:
    - protocol: TCP
      port: 443
      targetPort: 443
---
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: php-admin
  namespace: ${CP4BA_AUTO_NAMESPACE}
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
# credenziali admin per console php-admin per amministrazione OpenLDAP
# user: cn=admin,dc=example,dc=org
# estrarre password con comando
oc -n ${CP4BA_AUTO_NAMESPACE} get secret icp4adeploy-openldap-secret -o jsonpath='{.data.LDAP_ADMIN_PASSWORD}' | base64 -d | xargs echo "password: "

#-----------------------------------------
# contenuto file LDIF (okkio al punto nel nome, usare escape \)
oc -n ${CP4BA_AUTO_NAMESPACE} get secret icp4adeploy-openldap-customldif -o jsonpath='{.data.ldap_user\.ldif}' | base64 -d

```

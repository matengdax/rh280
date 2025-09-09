[toc]
## <strong style='color: #00B9E4'>P. 考试说明</strong>

1. 大多数题可以使用网页做
2. 网页登录，使用的地址、帐号、密码考题中都会提供
3. 命令行，需要先 ssh 至 workbech。主机名、帐号、密码考题中都会提供

## <strong style='color: #00B9E4'>L. 练习要求</strong>

### 1. HTPasswd

> Configure your OpenShift cluster to use an HTPasswd identity provider with the following requirements:
>
> - [ ] The name of the identity provider is: `ex280-htpasswd`
> - [ ] The name of the secret is: `ex280-idp-secret`
> - [ ] The user account `armstrong` is present and can log in with password `indionce`
> - [ ] The user account `collins` is present and can log in with password `veraster`
> - [ ] The user account `aldrin` is present and can log in with password `roonkere`
> - [ ] The user account `jobs` is present and can log in with password `sestiver`
> - [ ] The user account `wozniak` is present and can log in with password `glegunge`, Configure `wozniak` to create a project
> - [ ] Delete virtual user

**[opsadm@workbench]**

```bash
 $ htpasswd
	`htpasswd` -b[cmBdpsDv] [-C cost] `passwordfile` `username` `password`
  -b  Use the password from the command line rather than prompting for it.
  ...

*$ htpasswd -bBc htpasswd armstrong indionce
*$ htpasswd -b htpasswd collins veraster
*$ htpasswd -b htpasswd aldrin roonkere
*$ htpasswd -b htpasswd jobs sestiver
*$ htpasswd -b htpasswd wozniak glegunge

*$ oc -n openshift-config \
     create secret generic ex280-idp-secret \
     --from-file htpasswd=htpasswd

 $ oc explain OAuth.spec
 $ oc explain OAuth.spec.identityProviders
 $ oc explain OAuth.spec.identityProviders.htpasswd
 $ oc explain OAuth.spec.identityProviders.htpasswd.fileData

*$ oc edit oauth cluster
```
```yaml
...
spec:
  identityProviders:
  - ldap:
    ...
  # 增加 6 行
  - htpasswd:
      fileData:
        name: ex280-idp-secret
    mappingMethod: claim
    name: ex280-htpasswd
    type: HTPasswd
```

> !!!**注意**：几分钟后，将开始重新布署后生效

```bash
*$ oc adm policy add-cluster-role-to-user cluster-admin jobs

*$ oc get clusterrolebinding -o wide | egrep 'NAME|self'
 NAME                ROLE                          AGE   `GROUPS`                      ...
`self-provisioners`  ClusterRole/self-provisioner  119d  `system:authenticated:oauth`  ...

*$ oc adm policy add-cluster-role-to-user self-provisioner wozniak

*$ oc adm policy remove-cluster-role-from-group self-provisioner system:authenticated:oauth
 Warning: Your changes may get lost whenever a master is restarted, unless you prevent reconciliation of this rolebinding using the following command: "oc annotate clusterrolebinding.rbac self-provisioners 'rbac.authorization.kubernetes.io/autoupdate=false' --overwrite"
...

*$ oc annotate clusterrolebinding.rbac self-provisioner 'rbac.authorization.kubernetes.io/autoupdate=false' --overwrite
```

```bash
*$ oc -n kube-system delete secrets kubeadmin

```

### 2. add-role-to-user

> Configure your OpenShift cluster to meet the following requirements:
>
> ​	The following projects exist:
>
> - [ ] apollo
> - [ ] manhattan
> - [ ] gemini
> - [ ] bluebook
> - [ ] titan
>
> The user account `armstrong` is an `administrator` for project `apollo` and project `gemini`
>
> The user account `wozniak` can `view` project `titan` but not administer or delete it

**[opsadm@workbench]**

```bash
*$ oc -n apollo adm policy add-role-to-user admin armstrong
*$ ^apollo^gemini

*$ oc -n titan adm policy add-role-to-user view wozniak

```
**grade**

```bash
$ oc -n apollo policy who-can delete deploy | grep -w armstrong
        armstrong
$ oc -n gemini policy who-can delete deploy | grep -w armstrong
        armstrong

$ oc -n titan policy who-can delete pod | grep -w wozniak
$ oc -n titan policy who-can get pod | grep -w wozniak
        wozniak

```

### 3. user account

> Configure your OpenShift cluster to meet the following requirements:
>
> - [ ] The user account `armstrong` is a member of the `commander` group
> - [ ] The user account `collins` is a member of the `pilot` group
> - [ ] The user account `aldrin` is a member of the `pilot` group
> - [ ] Members of the `commander` group have `edit` permission in the `apollo` project
> - [ ] Members of the `pilot` group have `view` permission in the `apollo` project

**[opsadm@workbench]** 

```bash
*$ oc adm groups new commander
*$ oc adm groups new pilot

*$ oc adm groups add-users commander armstrong
*$ oc adm groups add-users pilot collins
*$ oc adm groups add-users pilot aldrin

*$ oc -n apollo adm policy add-role-to-group edit commander
*$ oc -n apollo adm policy add-role-to-group view pilot

```
**grade**

```bash
$ oc -n apollo policy who-can patch pod | grep -w commander
Groups: `commander`

$ oc -n apollo policy who-can patch pod | grep -w pilot
$ oc -n apollo policy who-can get pod | grep -w pilot
```

### 4. use quotas

> Configure your OpenShift cluster to use quotas in the `manhattan` project with the following requirements:
>
> - [ ] The name of the quota is: `ex280-quota`
> - [ ] The amount of memory consumed across all containers may not exceed `1Gi`
> - [ ] The total amount of CPU consumed across all containers may not exceed `2` full cores
> - [ ] The maximum number of replication controllers does not exceed `3`
> - [ ] The maximum number of pods does not exceed `3`
> - [ ] The maximum number of services does not exceed `6`

**[opsadm@workbench]**

```bash
*$ oc project manhattan

*$ oc create quota ex280-quota \
   --hard=cpu=2,memory=1Gi,pods=3,services=6,replicationcontrollers=3
   
```
**grade**

```bash
$ oc -n manhattan describe quota ex280-quota
Name: ex280-quota
Namespace: manhattan
Resource               Used Hard
--------               ---- ----
cpu                    0    2
memory                 0    1Gi
pods                   0    3
replicationcontrollers 0    3
services               0    6
```

### 5. LimitRange

> Configure your OpenShift cluster to use limits in the `bluebook` project with the following requirements:
>
> - [ ] The name of the limit range is: `ex280-limits`
> - [ ] The amount of memory consumed by a single pod is between `5Mi` and `300Mi`
> - [ ] The amount of memory consumed by a single container is between `5Mi` and `300Mi` with a default request of `100Mi`
> - [ ] The amount of CPU consumed by a single pod is between `10m` and `500m`
> - [ ] The amount of CPU consumed by a single container is between `10m` and `500m` with a default request of `100m`

**[opsadm@workbench]**

```bash
*$ oc project bluebook

 $ oc api-resources | egrep 'NAME|limit'
 NAME          SHORTNAMES  APIVERSION  NAMESPACED  KIND
 limitranges   limits     `v1`         true       `LimitRange`
 $ oc explain limitrange
 $ oc explain limitrange.spec
 $ oc explain limitrange.spec.limits

 $ echo set nu ts=2 et sw=2 cuc paste > ~/.vimrc

*$ vim limitrange.yml
```

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: ex280-limits
  namespace: bluebook
spec:
  limits:
  - type: Pod
  	min:
      memory: 5Mi
      cpu: 10m
    max:
      memory: 300Mi
      cpu: 500m
  - type: Container
      min:
        memory: 5Mi
        cpu: 10m
      max:
        memory: 300Mi
        cpu: 500m
      defaultRequest:
        memory: 100Mi
        cpu: 100m
```

```bash
*$ oc apply -f limitrange.yml
```

**grade**

```bash
$ oc -n bluebook describe limitranges
Name:       ex280-limits
Namespace:  bluebook
Type        Resource  Min  Max    Default Request  Default Limit  Max Limit/Request Ratio
----        --------  ---  ---    ---------------  -------------  -----------------------
Pod         memory    5Mi  300Mi  -                -              -
Pod         cpu       10m  500m   -                -              -
Container   cpu       10m  500m   100m             500m           -
Container   memory    5Mi  300Mi  100Mi            300Mi          -
```

### 6. scale

> Ensure that there are exactly `5` replicas of the minion application in the `gru` project

**[opsadm@workbench]**

```bash
*$ oc project gru

*$ oc status
 `dc/minion` deploys registry.ocp4.example.com:8443/redhattraining/hello-world-nginx:latest
 ...

*$ oc scale dc/minion --replicas 5

```

**grade**

```bash
$ oc get po
NAME              READY   STATUS      RESTARTS   AGE
minion-1-deploy   0/1     Completed   0          55s
minion-1-g6rkm    1/1    `Running`    0          54s
minion-1-4w7xb    1/1    `Running`    0          6s
minion-1-684lg    1/1    `Running`    0          6s
minion-1-b8k4h    1/1    `Running`    0          6s
minion-1-s97tp    1/1    `Running`    0          6s
```

### 7. Scale an application automatically

> Automatically scale the hydra deployment in the `lerna` project with the following requirements:
> 
> - [ ] Minimum number of pods: `6`
> - [ ] Maximum number of pods: `9`
> - [ ] Target average CPU utilization per pod: `60` percent
> - [ ] The pods require `25m` CPU time to operate
> - [ ] The pods must not consume more than `100m` CPU time

**[opsadm@workbench]**

```bash
*$ oc project lerna

*$ oc status
`dc/hydra` deploys registry.ocp4.example.com:8443/redhattraining/hello-world-nginx:latest
...

 $ oc set resources -h
*$ oc set resources dc/hydra \
   --limits=cpu=100m \
   --requests=cpu=25m

 $ oc autoscale -h
*$ oc autoscale deploymentconfig/hydra \
   --min 6 \
   --max 9 \
   --cpu-percent=60

```

**grade**

```bash
$ oc get po
NAME             READY   STATUS      RESTARTS   AGE
hydra-1-deploy   0/1     Completed   0          3m31s
hydra-2-deploy   0/1     Completed   0          2m49s
hydra-2-vpwj9    1/1    `Running`    0          109s
hydra-2-cjp8s    1/1    `Running`    0          77s
hydra-2-g2jhn    1/1    `Running`    0          77s
hydra-2-gm2sc    1/1    `Running`    0          77s
hydra-2-lmmcr    1/1    `Running`    0          77s
hydra-2-xrvq6    1/1    `Running`    0          77s
```

### 8. route

> Configure the `oxcart` application in the `area51` project with the following requirements:
>
> - [ ] The application uses a secure route called `oxcart`
>- [ ] Traffic between the client and the router is `encrypted`
> - [ ] Traffic between the router and the service is `unencrypted`
>- [ ] The route uses a CA signed certificate with the following subject fields:
>   `/C=CN/ST=BJ/L=beijing/O=RedHat/OU=RHT/CN=classified.apps.ocp4.example.com`
>
> - [ ] The application is reachable only at the following address:
>  https://classified.apps.ocp4.example.com
> 
>- [ ] The application produces output
>   A utility script called `newcert` has been provided on the workbench system to create the CA signed certificate
>    You may enter the certificate parameters manually or pass the subject as a parameter.
> 
>Your certificate signing request will be uploaded to the CA where it will be immediately signed and then downloaded to your current directory.
> 

**[opsadm@workbench]**

```bash
*$ oc project area51

*$ newcert /C=CN/ST=BJ/L=beijing/O=RedHat/OU=RHT/CN=classified.apps.ocp4.example.com

*$ oc get route
 NAME     HOST/PORT                          PATH   SERVICES   PORT       ...
 `oxcart` classified.apps.ocp4.example.com         `oxcart`    8080-tcp   ...

*$ oc delete route oxcart

*$ oc create route edge \
   --service oxcart \
   --hostname classified.apps.ocp4.example.com \
   --key classified.apps.ocp4.example.com.key \
   --cert classified.apps.ocp4.example.com.crt

```

**grade**

```bash
$ curl -vI https://classified.apps.ocp4.example.com
...
* Server certificate:
*  subject: C=CN; ST=BJ; L=beijing; O=RedHat; OU=RHT; CN=classified.apps.ocp4.example.com
*  start date: Jul  2 12:23:25 2024 GMT
*  expire date: Jul  1 12:23:25 2029 GMT
*  subjectAltName: host "classified.apps.ocp4.example.com" matched cert's "*.apps.ocp4.example.com"
*  issuer: C=US; ST=North Carolina; L=Raleigh; O=Red Hat; CN=ocp4.example.com
*  `SSL certificate verify ok.`
...
```

### 9. Deploy an application

> - [ ] Deploy the chart named `ascii-movie` in the project `redhat-movie` from the repository
>
> http://helm.ocp4.example.com/charts name `ex280-repo`
>
> - [ ] You may use the `telnet` or `nc` commands to validate the deployment

**[opsadm@workbench]**

```bash
*$ oc project redhat-movie

*$ helm repo add ex280-repo http://helm.ocp4.example.com/charts

*$ helm search repo
 NAME                     CHART VERSION	 APP VERSION   DESCRIPTION
 ex280-repo/ascii-movie   0.16.1       	 1.9.3         Star Wars movie SSH and Telnet server
 ...

*$ helm install redhat-movie ex280-repo/ascii-movie

```
**grade**

```bash
$ oc get all
NAME                                           READY   STATUS    RESTARTS   AGE
pod/redhat-movie-ascii-movie-5b8f6548f-bpfcf   1/1     Running   0          74s

NAME                                   TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                     AGE
service/redhat-movie-ascii-movie       LoadBalancer   172.30.232.20    `192.168.50.20`   22:31626/TCP,23:32322/TCP   74s
service/redhat-movie-ascii-movie-api   ClusterIP      172.30.240.198   <none>          1977/TCP                    74s

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/redhat-movie-ascii-movie   1/1     1            1           74s

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/redhat-movie-ascii-movie-5b8f6548f   1         1         1       74s
```

```bash
$ nc 192.168.50.20 23
  <Ctrl-C>
  
$ telnet 192.168.50.20
  <q>
```

### 10. Configure a secret

> Configure a secret in the `math` project with the following requirements:
> 
> - [ ] The name of the secret is: `magic`
> - [ ] The secret defines a key with name: `decoder_ring`
> - [ ] The secret defines the key with value: `6YWN572u5q2j56GuCg==`

**[opsadm@workbench]**

```bash
*$ oc project math

 $ oc create secret generic -h
*$ oc create secret generic magic \
   --from-literal decoder_ring=6YWN572u5q2j56GuCg==

```

**grade**

```bash
$ oc extract secret/magic --to=-
# decoder_ring
6YWN572u5q2j56GuCg==
```

### 11. Configure an application to use a secret

> Configure the application called `qed` in the `math` project with the following requirements:
>
> - [ ] The application uses the secret previously created called: `magic`
> - [ ] The secret defines an environment variable with name: `DECODER_RING`
> - [ ] The application output no longer displays: `Sorry, application is not configured correctly.`

**[opsadm@workbench ~]**

```bash
 $ oc project math

*$ oc status
`dc/qed` deploys registry.ocp4.example.com:8443/redhattraining/hello-world-nginx
 ...

 $ oc set env -h
*$ oc set env dc/qed --from=secret/magic

```

**grade**

```bash
$ oc rsh dc/qed env | grep DECODER_RING
DECODER_RING=XpWy9KdcP3Tr9FFHGQgZgVRCKukQdrQsbcl0c2ZYhDk=
```

### 12. Configure a service account

> Configure a service account in the `apples` project to meet the following requirements:
>
> - [ ] The name of the service account is `ex280sa`
> - [ ] The service account allows pods to be run as any available user

**[opsadm@workbench ~]**

```bash
*$ oc project apples

*$ oc create serviceaccount ex280sa
 $ oc get sa

 $ oc get scc
 NAME                              PRIV    CAPS                   ...
 `anyuid`                          false   <no value>             ...
 ...
*$ oc adm policy add-scc-to-user anyuid -z ex280sa

 $ oc get clusterrole | grep cluster.*admin
 `cluster-admin`   YYYY-MM-DDThh:mm:ssZ
 ...
*$ oc adm policy add-cluster-role-to-user cluster-admin -z ex280sa

```

### 13. uses the service account

>Deploy the application called `oranges` in the `apples` project so that the following conditions are true:
>
>- [ ] The application uses the `ex280sa` service account
>- [ ] No configuration components have been added or removed
>- [ ] The application produces output

**[opsadm@workbench ~]**

```bash
*$ oc project apples

*$ oc status
`dc/oranges` deploys registry.ocp4.example.com:8443/ubi9/httpd-24:latest
...

*$ oc set sa dc/oranges ex280sa

 $ oc get svc
 NAME      TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
 oranges  `NodePort` `172.30.131.196`  <none>       `8080`:`31449`/TCP   28h
 $ oc get no -o wide
 NAME       STATUS  ROLES                        AGE   VERSION           INTERNAL-IP    ...
`master01`  Ready   control-plane,master,worker  282d  v1.25.4+77bec7a  `192.168.50.10` ...
 $ curl 192.168.50.10:31449
 curl: (7) Failed to connect to master01 port 30756: Connection refused

 $ oc get po -o wide
 ...
 oranges-2-vgjkv    1/1     Running     0          8m35s   `10.8.0.220`   master01   ...
 $ oc rsh dc/oranges curl 10.8.0.220:8080 && echo ok
 $ oc rsh dc/oranges curl 172.30.131.196:8080 || echo no

 $ oc get po --show-labels
 NAME               READY   STATUS      RESTARTS   AGE   LABELS
 ...
 oranges-2-vgjkv    1/1     Running     0          12m   `deployment-config.name=oranges`,deployment=oranges-2,deploymentconfig=oranges
*$ oc edit svc/oranges
```

```yaml
...
  selector:
   #deployment-config.name: orange
    deployment-config.name: oranges
    ...
```

**grade**

```bash
$ curl 192.168.50.10:31449
<html>
  <body>
    <h1>Hello, world from nginx!</h1>
  </body>
</html>
```

### 14. request memory

>Deploy the application called `atlas` in the `mercury` project so that the following conditions are true:
>
>- [ ] No configuration components have been added or removed
>
>- [ ] The application produces output

**[opsadm@workbench ~]**

```bash
*$ oc project mercury

*$ oc status
 http://atlas-mercury.apps.ocp4.example.com to pod port 8080-tcp (svc/atlas)
  deployment/atlas deploys istag/atlas:latest
  ...

 $ oc set resources -h
*$ oc edit deployment/atlas
```

```yaml
...
        resources:
          requests:
           #memory: 10000Mi
            memory: 128Mi
            ...
```

**grade**

```bash
$ oc status

$ curl http://atlas-mercury.apps.ocp4.example.com
```

### 15. Configure application data

>Deploy an application using the `registry.ocp4.example.com:8443/redhattraining/hello-openshift` image that meets the following requirements:
>
>- [ ] The application is part of a project named: `acid`
>
>- [ ] The application is named: `phosphoric`
>
>- [ ] The application uses a key named `RESPONSE` in a configuration map named `sedicen`
>
>- [ ] The application is running and available at http://phosphoric-acid.apps.ocp4.example.com and displays the following initial text:
>  `Soda pop won't stop can't stop`
>
>- [ ] Re-deploying the application after making changes to the configuration map results in a corresponding change to the displayed text

**[opsadm@workbench ~]**

```bash
*$ oc project acid

*$ oc create configmap sedicen \
   --from-literal RESPONSE="Soda pop won't stop can't stop"

*$ oc new-app \
   --name phosphoric \
   --image registry.ocp4.example.com:8443/redhattraining/hello-openshift

*$ oc set env deployment/phosphoric --from=configmap/sedicen

*$ oc expose svc/phosphoric \
   --hostname=phosphoric-acid.apps.ocp4.example.com
```

**grade**

```bash
$ curl phosphoric-acid.apps.ocp4.example.com
Soda pop won't stop can't stop
```

### 16. network policy

>Configure a network policy using the `database` and `checker` projects with the following requirements:
>
>- [ ] The `database` project has network policy with the name `db-allow-mysql-conn` based on pod selector label `network.openshift.io/policy-group`
>
>- [ ] Connections to the `database` project are restricted to deployments from the `checker` project
>
>- [ ] The network policy is filtered by project selector using the `team=devsecops` label and pod selector using the `deployment=web-mysql` label
>
>- [ ] The application can establish a connection to port `3306/TCP`
>
>You can check your work by examining the logs in the `checker` project

**[opsadm@workbench ~]**

```bash
*$ oc project database

*$ oc get networkpolicies
 NAME          POD-SELECTOR   AGE
 db-deny-all   <none>         115s

*$ vim db-networkpolicy.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-allow-mysql-conn
  namespace: database
spec:
  podSelector:
    matchLabels:
      network.openshift.io/policy-group: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          deployment: web-mysql
      namespaceSelector:
        matchLabels:
          team: devsecops
    ports:
    - protocol: TCP
      port: 3306
```

```bash
*$ oc apply -f db-networkpolicy.yaml

```

**grade**

```bash
$ POD_IP=$(oc get pod -n database -o jsonpath='{.items[0].status.podIP}')

$ oc -n checker rsh deployments/test \
    mysql -h ${POD_IP} -uroot -predhat -e "show databases;"
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```

### 17. template

>Configure your OpenShift cluster so that new projects are created with limits using the following requirements:
>
>- [ ] The name of the limit range is: `PROJECT_NAME-limits` where `PROJECT_NAME` is the name of the project created using oc new-project
>
>- [ ] The amount of memory consumed by a single container is between `128Mi` and `1Gi` with a default of `512Mi` and a default request of `256Mi`

**[opsadm@workbench ~]**

```bash
 $ oc adm create-bootstrap-project-template -h
*$ oc adm create-bootstrap-project-template -o yaml > 17.yml

 $ oc get limitranges -A
 $ oc get limitranges -A -o yaml | grep -v cpu

*$ vim 17.yml
```

```yaml
apiVersion: template.openshift.io/v1
kind: Template
metadata:
  name: project-request
  # 增加 1 行
  namespace: openshift-config
objects:
- apiVersion: project.openshift.io/v1
  kind: Project
  metadata:
    annotations:
      openshift.io/description: ${PROJECT_DESCRIPTION}
      openshift.io/display-name: ${PROJECT_DISPLAYNAME}
      openshift.io/requester: ${PROJECT_REQUESTING_USER}
    name: ${PROJECT_NAME}
  spec: {}
- apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    name: admin
    namespace: ${PROJECT_NAME}
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: admin
  subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: ${PROJECT_ADMIN_USER}
# >>>> 添加 BEGIN
- apiVersion: v1
  kind: LimitRange
  metadata:
    # The name of the limit range
    name: ${PROJECT_NAME}-limits
    namespace: ${PROJECT_NAME}
  spec:
    limits:
    # a single container
    - type: Container
      min:
        memory: 128Mi
      max:
        memory: 1Gi
      default:
        memory: 512Mi
      defaultRequest:
        memory: 256Mi
# <<<< 添加 END
parameters:
- name: PROJECT_NAME
- name: PROJECT_DISPLAYNAME
- name: PROJECT_DESCRIPTION
- name: PROJECT_ADMIN_USER
- name: PROJECT_REQUESTING_USER
```

```bash
*$ oc apply -f 17.yml

*$ oc api-resources | egrep -iw 'name|project'
 $ oc explain -h
*$ oc explain --api-version=config.openshift.io/v1 project
*$ oc explain --api-version=config.openshift.io/v1 project.spec
*$ oc explain --api-version=config.openshift.io/v1 project.spec.projectRequestTemplate

*$ oc edit projects.config.openshift.io cluster
```

```yaml
...
#spec: {}
spec:
  projectRequestTemplate:
    name: project-request
```

**grade**

```bash
$ watch oc get pod -n openshift-apiserver
NAME                        READY   STATUS    RESTARTS   AGE
apiserver-5774cb6f8-j2ndh  `2/2`   `Running`  0          19m
<Ctrl+C>

$ oc new-project test

$ oc get limitranges
NAME          CREATED AT
test-limits   YYYY-MM-DDThh:mm:ssZ
```

### 18. operator

>Install the file-integrity operator with the following requirements:
>
>- [ ] The operator is installed in the `openshift-file-integrity` project
>
>- [ ] The approval strategy is `Automatic`
>- [ ] Cluster monitoring is enabled for the openshift-file-integrity project

**[opsadm@workbench ~]**

```bash
$ oc whoami --show-console
https://console-openshift-console.apps.ocp4.example.com
```

<img src='https://www.firefox.com.cn/media/protocol/img/logos/firefox/logo-word-hor.96f28a0f9ae6.svg' width='60'> https://console-openshift-console.apps.ocp4.example.com

​	<kbd>Operators</kbd> / <kbd>operatorHub</kbd> /

​	  :mag: `file` <kbd>Enter</kbd> /

​	    <img src="https://gitlab.com/opensu/openshift/-/raw/main/File_Intergrity_Operator.png" width=38><kbd>File Intergrity Operator</kbd> / <kbd>Install</kbd> /

​	      Installation mode *
​ ​   ​  ​ ​  ​ ​ ​ ​ ​ :radio_button: A specific namespace on the cluster
​	      Installed Namespace *​ 
​  ​ ​ ​ ​ ​  ​  ​ ​ ​ ​ :radio_button: Operator recommended Namespace: Project: openshift-file-integrity
​                 :ballot_box_with_check: Enable Operator recommended cluster monitoring on this Namespace
​             Update approval *
​              :radio_button: Automatic
​             <kbd>Install</kbd>

### 19. cron job

> Create a cron job using the image at `registry.ocp4.example.com:8443/redhattraining/hello-world-nginx` with the following requirements:
>
> - [ ] The cron job name is `job-runner`
> - [ ] The cron job runs at `04:05` on the `2nd` day of `every month`
> - [ ] The successful job history limit is `14`
> - [ ] The service account and service account name is `magna`
> - [ ] The cron job runs in the project called `elementum`

**[opsadm@workbench ~]**

```bash
*$ oc new-project elementum

*$ oc create sa magna
  
 $ oc explain cronjob.spec | grep -i succ
   successfulJobsHistoryLimit	<integer>
   ...
*$ oc create cronjob job-runner \
   --image=registry.ocp4.example.com:8443/redhattraining/hello-world-nginx \
   --schedule="5 4 2 * *" \
   --dry-run=client \
   -o yaml > 19.yml

*$ vim 19.yml
```

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: job-runner
  # 增加 1 行 [可选]
  namespace: elementum
spec:
  # 增加 1 行
  successfulJobsHistoryLimit: 14
  jobTemplate:
    metadata:
      name: job-runner
    spec:
      template:
        spec:
          serviceAccountName: magna
          containers:
          - image: registry.ocp4.example.com:8443/redhattraining/hello-world-nginx
            name: job-runner
            resources: {}
          restartPolicy: OnFailure
  schedule: 5 4 2 * *
status: {}
```

```bash
*$ oc create -f 19.yml

*$ oc set sa cronjob/job-runner magna

```

**grade**

```bash
$ oc get all
NAME                       SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/job-runner   5 4 2 * *   False     0        <none>          58s
```

### 20. Collect the default support information

> Collect the default support information for your OpenShift cluster with the following requirements:
>
> - [ ] The data is stored as a compressed tar archive using: `tar cvaf`
>
> - [ ] The name of the compressed tar archive is: `ex280-ocp-clusterID.tar.gz`
>
> where clusterID is the unique identifier of your OpenShift cluster
>
> ​	The archive has been uploaded for grading
>
> A utility script has been provided for you to upload the archive as follows:
>
> ​	`/usr/local/bin/upload-cluster-data ex280-ocp-clusterID.tar.gz`
>
> You may upload the archive as many times as necessary. Each uploaded archive will overwrite any previously uploaded archive.

**[opsadm@workbench ~]**

```bash
*$ oc adm must-gather
...
ClusterID: `b1d661ca-7fb3-42e2-a62a-968b80672189`
ClusterVersion: Stable at "4.14.0"
ClusterOperators:
	All healthy and stable

*$ tar cvaf ex280-ocp-b1d661ca-7fb3-42e2-a62a-968b80672189.tar.gz must<Tab>

*$ /usr/local/bin/upload-cluster-data ex280-ocp-b1d661ca-7fb3-42e2-a62a-968b80672189.tar.gz

```

### 21. A storage class has been configured to provide NFS storage

> Using information from that storage class, configure a persistent volume with the following requirements:
>
> - [ ] Name: `landing-pv`
> - [ ] Access mode: `ReadOnlyMany`
> - [ ] Size: `1Gi`
> - [ ] The reclaim policy matches the storage class
>
> Configure a persistent volume claim with the following requirements:
>
> - [ ] Name: `landing-pvc`
> - [ ] The access mode is the same as the persistent volume
> - [ ] The size is the same as the persistent volume
>
> Deploy the application with the following requirements:
>
> - [ ] The application exists in a project called `page`
>
> - [ ] The application uses a deployment called `landing`
>
> - [ ] The application uses the image hosted at `registry.ocp4.example.com:8443/redhattraining/hello-world-nginx`
>
> - [ ] The nginx mountpoint is `/usr/share/nginx/html`
>
> - [ ] The application uses `3` pods
>
> - [ ] The application is accessible at https://landing-page.apps.ocp4.example.com

PS: 建议使用 <img src='https://www.firefox.com.cn/media/protocol/img/logos/firefox/logo-word-hor.96f28a0f9ae6.svg' width='60'>网页 完成

**[opsadm@workbench ~]**

```bash
 $ oc get storageclasses
*$ oc get storageclasses nfs-storage -o yaml
 reclaimPolicy: `Delete`
 ...
 
 $ oc get po -A | grep nfs
 $ oc -n nfs-client-provisioner get all
*$ oc -n nfs-client-provisioner get deployment/nfs-client-provisioner -o yaml
 ...
        nfs:
          path: `/exports-ocp4`
          server: `192.168.50.254`
          
*$ vim nfs-pv.yml
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: landing-pv
spec:
  accessModes:
  - ReadOnlyMany
  capacity:
    storage: 1Gi
  storageClassName: nfs-storage
 #storageClassName: nfs-client
  persistentVolumeReclaimPolicy: Delete
  nfs:
    path: /exports-ocp4
    server: 192.168.50.254
   #path: /nfsshare
   #server: workstation.ocp4.example.com
```

```bash
*$ oc apply -f nfs-pv.yml

*$ oc project page

*$ vim nfs-pvc.yml
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: landing-pvc
spec:
  accessModes:
    - ReadOnlyMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-storage
  volumeName: landing-pv
```

```bash
*$ oc apply -f nfs-pvc.yml

*$ oc new-app \
   --name landing \
   --image registry.ocp4.example.com:8443/redhattraining/hello-world-nginx

*$ oc set volumes deployment/landing \
   --add \
   --name web-volume \
   --type pvc \
   --claim-name landing-pvc \
   -m /usr/share/nginx/html

*$ oc scale deployment/landing --replicas 3

*$ rm -r classified*
*$ newcert /C=CN/ST=BJ/L=beijing/O=RedHat/OU=RHT/CN=landing-page.apps.ocp4.example.com

*$ oc create route edge landing \
   --service=landing \
   --hostname=landing-page.apps.ocp4.example.com \
   --key classified.apps.ocp4.example.com.key \
   --cert classified.apps.ocp4.example.com.crt

```

**grade**

```bash
$ curl -vI https://landing-page.apps.ocp4.example.com
```

### 22. liveness probe

> An application named `atlas` has been deployed with a single container in the `mercury` project
>
> Implement a `liveness` probe for this container that meets the following requirements:
>
> - [ ] The probe monitors liveness by performing a `TCP` socket check on port `8080`
> - [ ] The probe has an initial delay of `10` seconds and a timeout of `30` seconds
> - [ ] Your changes can survive a rebuild

PS: 建议使用 <img src='https://www.firefox.com.cn/media/protocol/img/logos/firefox/logo-word-hor.96f28a0f9ae6.svg' width='60'>网页 完成

**[opsadm@workbench ~]**

```bash
*$ oc project mercury

*$ oc status
  `deployment/atlas` deploys istag/atlas:latest
  ...

 $ oc set probe --help
*$ oc set probe deployment/atlas \
   --liveness \
   --open-tcp=8080 \
   --initial-delay-seconds=10 \
   --timeout-seconds=30

```

## O. OBJECTIVE

> **SCORE**
>
> - [ ] Manage OpenShift Container Platform
> - [ ] Deploy applications
> - [ ] Manage storage for application configuration and data
> - [ ] Configure applications for reliability
> - [ ] Manage authentication and authorization
> - [ ] Configure network security
> - [ ] Enable developer self-service
> - [ ] Manage OpenShift operators
> - [ ] Configure application security

[toc]
## <strong style='color: #00B9E4'>P. 考试说明</strong>

1. 大多数题可以使用网页做
2. 网页登录，使用的地址、帐号、密码考题中都会提供
3. 命令行，需要先 ssh 至 workbech。主机名、帐号、密码考题中都会提供

## <strong style='color: #00B9E4'>C. 模拟客户端</strong>

- 物理机

  ```bash
  # >>>> Modifies crc configuration properties
  # * kubeadmin-password: User defined kubeadmin password
  crc config set kubeadmin-password redhatocp
  
  # >>>> Start the instance
  # * disk-size: Total size in GiB of the disk ( >= '31')
  # * memory: Memory size in MiB ( >= '10752')
  crc start -d 50 -m 12288 -p pull-secret.txt
  ```

  ```bash
  # >>>> Add the 'oc' executable to PATH
  eval $(crc oc-env)
  
  # >>>> Client
  oc -n default run workbench -it \
    --image quay.io/openshift/origin-cli:4.17 -- sleep infinity
  ```

  新开个终端

  ```bash
  oc -n default rsh workbench
  ```

  

- 容器中

  **[root@workbench /]#**

  ```bash
  # >>>> [1/4] repo disable for fast
  dnf config-manager --disable rhel-9-server-ose centos-ceph-quincy centos-nfv-openvswitch centos-openstack-zed centos-rabbitmq-38 extras-common rt
  
  # >>>> [2/4] bash-completion
  dnf -y install bash-completion sudo vim-enhanced nc telnet git
  
  # >>>> [3/4] account
  useradd opsadm
  echo 'opsadm ALL=(ALL)	NOPASSWD: ALL'> /etc/sudoers.d/opsadm
  su - opsadm
  
  ```
  
  ```bash
  # >>>> oc
  oc login -u kubeadmin -p redhatocp https://api.crc.testing:6443 \
    --insecure-skip-tls-verify
  
  oc completion bash > ~/.kube/completion.bash.inc
  echo "source '$HOME/.kube/completion.bash.inc'" >> $HOME/.bash_profile
  source $HOME/.bash_profile
  
  ```

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

**prepare**

```bash
# 1. 

# >>>> htpasswd
sudo dnf -y install httpd-tools

```

**operation**

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

**prepare**

```bash
# 4. 

# >>>> project
oc new-project manhattan

```

**operation**

```bash
*$ oc project manhattan

 $ oc create quota -h
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

**prepare**

```bash
# 5.

# >>>> project
oc new-project bluebook

```

**operation**

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
----        --------  ---  ---    ---------------  -------------  --------------
Pod         memory    5Mi  300Mi  -                -              -
Pod         cpu       10m  500m   -                -              -
Container   cpu       10m  500m   100m             500m           -
Container   memory    5Mi  300Mi  100Mi            300Mi          -
```

### 6. scale

> Ensure that there are exactly `5` replicas of the minion application in the `gru` project

**[opsadm@workbench]**

**prepare**

```bash
# 6.

# >>>> project
oc new-project gru

# >>>> app
oc -n gru create deploymentconfig minion \
  --image quay.io/redhattraining/hello-world-nginx
```

**operation**

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

**prepare**

```bash
# 7.

# >>>> porject
oc new-project lerna

# >>>> app
oc -n lerna create deploymentconfig hydra \
  --image quay.io/redhattraining/hello-world-nginx

```

**operation**

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
>   `/C=CN/ST=BJ/L=beijing/O=RedHat/OU=RHT/CN=classified.apps-crc.testing`
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

**prepare**

```bash
# 8. 

# >>>> file
# [1/4] passphrase.txt
printf RedHat123@! > ~/passphrase.txt
# [2/4] training.ext
tee ~/training.ext >/dev/null<<EOT
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.crc.testing
DNS.2 = *.apps-crc.testing
EOT
# [3/4] training-CA.pem
tee ~/training-CA.pem >/dev/null<<EOP
-----BEGIN CERTIFICATE-----
MIIEqzCCAxOgAwIBAgIUfRY6HYgttNwEGTrEa+Os/i6Ej4swDQYJKoZIhvcNAQEL
BQAwZTELMAkGA1UEBhMCVVMxFzAVBgNVBAgMDk5vcnRoIENhcm9saW5hMRAwDgYD
VQQHDAdSYWxlaWdoMRAwDgYDVQQKDAdSZWQgSGF0MRkwFwYDVQQDDBBvY3A0LmV4
YW1wbGUuY29tMB4XDTI0MDcwMjAyMTk1MVoXDTI5MDcwMTAyMTk1MVowZTELMAkG
A1UEBhMCVVMxFzAVBgNVBAgMDk5vcnRoIENhcm9saW5hMRAwDgYDVQQHDAdSYWxl
aWdoMRAwDgYDVQQKDAdSZWQgSGF0MRkwFwYDVQQDDBBvY3A0LmV4YW1wbGUuY29t
MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAr2LzZyqSnFKuaKFPYXMa
d/MUbR3AcTlEgu2BaC9rQCpnGJ5ioepcJqI67Y30pHYy1IY//LzeJzvRzZHO8WTi
yTzSJ6Mjp43o/uYgsXk87u7scHY0z6+zN+IASRFMNNl0Y/VAc3S7bOP4GcS+1a39
As1Q9YRctGZNE4yv5JsLCzmVwtldguZAOsURMHsb928DalRfr1e17vhqxJbTwxpz
YdT9Un/kxali0u802qos0QcSQq1LZmz7oVkrFL97Iona2d4fEjioDo3MFJs2HfCr
lJY1YBW3t1SK554UANBgUCK4RDiF9Z3NhQv6laL6OYrjrLr7IthgYhFrHm3GGPQM
1nGt8plvoo6CiV0aT1aM4aIRbu5b8T911MvUq0mfANQ1A6WT3SaECLZSJrkV+jmB
ZiGmV+pA0V35umzVnFn0loEU4/5hFNuFW8ly/Rs+s0Xd9yEDCVMfuyU8OJoccYa9
zcoNX6FKXqyBbYwJFzHPcqHwgjn1vyXPyrY86XaUGX2JAgMBAAGjUzBRMB0GA1Ud
DgQWBBTuK3c7LadG/H7n28AfTLxuTJTBzjAfBgNVHSMEGDAWgBTuK3c7LadG/H7n
28AfTLxuTJTBzjAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBgQAP
KATtPRaeAAgq+Hwslp4dDRcLhnvN4kTWBD+9oiQlO84rUF+OMexXANGdLm0IpFy6
xzark6KOANB4H4v+YTti6MDfuqOuguzjW9T2amWEA0Dh5HbFncIhciNbXSwN9WEO
HsITwCQo2uhOpQ/VNQYIBk9aBmngxaAjLhsZ2f8onM93FCjjoLJySJNsXQ+0tYaN
epegToP3KC1DxLEqbRBbSqecNERvlXaMFr/LB+asAuEJeVbi5hQSxPzmk+on0YF/
534GiAJt2c3TV0EB9JFpT3vnjtInaceSFPaQExrv+xaZRAGPg0Efqt+FXMU26CnR
zyMe0La3SIwDdELjxuWw22otsOo7iZaOoZ5p0sFVWu22vQ18MMJ4ux3zMQW4nQi7
KE5FnfXGoKZlk2MTEO/1H6jowknyAT6RP9z3UECc7tBATFais8a/JjAFv4CFBPAd
3vbqfuvYfm0dwpyek7UvPlWJe4k30GXs0L6VpCx5EqUiqF1HiOOFt99+ha/TH/c=
-----END CERTIFICATE-----
EOP
# [4/4] training-CA.key
tee ~/training-CA.key >/dev/null<<EOY
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,689B7D624F606E79

lpu788Tz75xaPTvSXKS07BUh0DMO1IshX+MAZHmiB+VLVWsXP42KKgSCahywt6AF
Thy+4ekQeWAtlHJ2Y+7bk2MObA4ODVmgDmPgsMK9PMaUkhieliMGqQVIyXfdjlRV
oFrJHiUWF8Ho5+4YWGjeU6w/wIyh4yu3xQ51pptMgbBZy8Zt4bQoEu/no2WGk0xX
A/oc90vuF/D3HI/LIo4xiaPkVLjLhnws8GtGQISADyJFg8Qpq5auBecpiBypnx/z
zUHSy1yH+k9OJem84pDJ3rj/mOagemUn54UkfjieLISTgFUp0IeKwERN9l2E5zgc
fFYHpizvlIDShZcdK+rlNgUqQXBwAlguQeXxyZ+LT3CJtVQuT0GdrqtZARYau0c3
yCJJ6Mw8SdMFav1g7Wdd2b2HUqpDNbARV2Jo7gcFoVy5mTNlY+KD7W1MxtR123s5
vh4BFBFB5b2/vxHGulW4aBaG/uIiEe6FBQ5U6B6dXR9/TKgPPcLSkgQ9JfRoSFXE
Bn0fCvuRe4HUO206NmdBX8C6zTTnbrPmiBGOUrDYSUHuEBYLiwxMH6NHA26JyYuK
PBCM0el5fS3Hfd21w5JTBoWZG0cXdUSL76t3wp5q78HoJqZKXMtPUk5MIovxmp/j
BRQo902QXVQsA7Hr3NFIT/fiZKkDVwrlQSyXsbYVjn+st9xwWViuJyASDet6y81M
YDJvz4jqAfRXdOuJw7PpF/Oo6bF3XCOBjhHovr/mu4s0pr1s2c4wvf3HICXZp+3O
Q4PW+/g0hLLV6mIwO1YQqFz5XKdbDs8VyD2HTmzzWtD2MR6HscA7FnIWcVrJMkjc
vWmkJOc0HVMM2RAQC2KSJUGenxTB3/CO/QB72ctKtq5HcBnLr5rogQkTG05qXqJc
oiwWileIe6DLta/Lju9HeZJLNRka88dFYoXE3vBkhVMqCdoHolIwT+csBvmaq22V
sKE4YESvTOPVoZZ+NnWWf111vs1XlAChy2sBLUPoXfVulII/c4P19p7dumLyc8Uc
8lZZrXBlA321EX3W8cCvP/vcEOWi406lgjQ5Nbj60yJLK7hTHuRnS87D0a3Xf3Kv
b53k36+rKa/F+xVE8KE+jIDYVkPvIpCup9iOZX6d5P466FTvAt6cKPl/U2wU9R8o
1CCLU6J8Ip9auG2sZ1YmiudU8r5pNDC7OQ7klFaTkLH6N8qtzaIIGIkX4/3jdvJ0
vcWlbn/DBsi8RxproRNF9iQ/ji9CuSFaHy6vPrYPvsgAi73rgy7EwCpps38SDGYJ
JwP46/gReWcqKJ2jxvULo50FRQglqvRSOgjA3BJCu7FxCE4T3P8EyLK09CDpwh0/
xU0whtfBjG4hae5S5uQVm6+JzYBCUAeKl3ZNcfslPv5H+LzYVzcq0CTQZN7V/lNu
4k3bYRmya2OJcPHKaOzWWE7PpUFR1LNxyDHTpN9pIphKX3tV2R91ct8nkTHSz8uY
iXxzUV593grj4vlWK7Q32vDNgfcB6lqv+fLn899kbKK7rlwM5Iq6hyzSc4NaCihr
LVx90nPlOg0TKPG01KoxdoTzohEWXgEwgwRKSAlvnbRWQLGSorGalpn5xGSvFU0k
RUDNLGepQ/DZDF+n2mRLgtDc4mMXC2k97ePiMtbHe55rMUMgPDlb6XrPpylZmlPA
oMah6neTboX6T9kCMV3xHVSlj2Jfx7fuF7FzDkFvndC+p2k59Xkw8XQqjQF4w4J+
ZMCATFH9OQAKN2ekVOvcYCW9Y0MAZqUvXe72ef2QYYvCaVsZnGzktIl2wa9vnOlX
BmPYnrzbYybyDpMTaWfXh3ZR0btjcW+Rn3wAIrN8oN9LqpZg941lsX6eaqYDFEd+
u7aZqFMhvyk8266bDlion+mdd2m8bFEceuIbgqJYRunhBTpsUF2wlkT38syUAWKy
Hh5T62GQNiFDJqi4qDFM5gAHv6UEsCkGc2GQi45SFt3XK3xjR1CVtfrK7Op0GdhG
6EiQuOsk1Y7LIvvZiF8LaE2w1QEugI/4MoaxkmfrWhn0nRM+hG+OqlCcRFKu6pKe
zCpU965sWOoo4alsLdM+5RS8YKXYmqKr+8z+qnAGtHCWGUayyfk9kS3sWFXqJ2aU
tU0W4ADvS59sDBwpcMN1wceFmiltYlAf6iBd1JlDUe/lh64dfVHxc6yJ4yMi9HqO
pvR5gBy4VsAbtPnbUQ6pcA96ZvlmKlqBnsCShaDMh2GHGC2B/97wVy6qTynjiGH/
3oiMl7A6xL+UfjYwviBvTQviF+XBQGVdRBbG1GRHGi7vgnzjWK5RVvJd0ff/H7W6
+ZB4cZsW+PpHt4oefsHx7z6KJiynZ8hB3WOHDV7J3oMJqUCOj08Gww==
-----END RSA PRIVATE KEY-----
EOY
# >>>> update-ca-trust
sudo cp ~/training-CA.pem /etc/pki/ca-trust/source/anchors/training-CA.pem 2>/dev/null
sudo update-ca-trust 2>/dev/null
# >>>> /usr/local/bin/newcert
sudo tee /usr/local/bin/newcert &>/dev/null<<EOF
#!/bin/bash
CN=classified.apps-crc.testing
echo "Generating a private key..."
openssl genrsa -out \${CN}.key 4096
echo -e "\nGenerating a CSR..."
openssl req -new -key \${CN}.key -out \${CN}.csr -subj \$1
echo -e "\nGenerating a certificate..."
openssl x509 -req -in \${CN}.csr \
  -passin file:/home/opsadm/passphrase.txt \
  -CA ~/training-CA.pem -CAkey ~/training-CA.key -CAcreateserial \
  -out \${CN}.crt -days 1825 -sha256 -extfile ~/training.ext \
  -clrext
echo -e "\nDONE.\n"
EOF
sudo chmod +x /usr/local/bin/newcert 2>/dev/null

# >>>> project
oc new-project area51
# >>>> app
oc -n area51 new-app --name oxcart \
  --image quay.io/redhattraining/hello-world-nginx
# >>>> route
oc -n area51 expose service/oxcart \
	--hostname classified.apps-crc.testing
```

**operation**

```bash
*$ oc project area51

*$ newcert /C=CN/ST=BJ/L=beijing/O=RedHat/OU=RHT/CN=classified.apps-crc.testing

*$ oc get route
 NAME      HOST/PORT                      PATH   SERVICES   PORT       ...
 `oxcart`  classified.apps-crc.testing          `oxcart`    8080-tcp   ...

*$ oc delete route oxcart

*$ oc create route edge \
   --service oxcart \
   --hostname classified.apps-crc.testing \
   --key classified.apps-crc.testing.key \
   --cert classified.apps-crc.testing.crt

```

**grade**

```bash
$ curl -vI https://classified.apps-crc.testing
...
* Server certificate:
*  subject: C=CN; ST=BJ; L=beijing; O=RedHat; OU=RHT; CN=classified.apps-crc.testing
*  start date: Dec  1 13:02:21 2024 GMT
*  expire date: Nov 30 13:02:21 2029 GMT
*  subjectAltName: host "classified.apps-crc.testing" matched cert's "*.apps-crc.testing"
*  issuer: C=US; ST=North Carolina; L=Raleigh; O=Red Hat; CN=ocp4.example.com
*  `SSL certificate verify ok.`
...
```

### 9. Deploy an application

> - [ ] Deploy the chart named `ascii-movie` in the project `redhat-movie` from the repository
>
> https://opensu.org:8443/charts name `ex280-repo`
>
> - [ ] You may use the `telnet` or `nc` commands to validate the deployment

**[opsadm@workbench]**

**prepare**

```bash
# 9.

# >>>> project
oc new-project redhat-movie
# >>>> scc
oc -n redhat-movie adm policy add-scc-to-user anyuid -z default
# >>>> helm
curl https://raw.gitmirror.com/helm/helm/main/scripts/get-helm-3 \
| sed -e 's+https://github.com+https://hub.gitmirror.com/https://github.com+' \
  -e 's+raw.githubusercontent.com+raw.gitmirror.com+' \
| bash
source <(helm completion bash)
helm completion bash | sudo tee /etc/bash_completion.d/helm >/dev/null

# >>>> 下面完成后，可以使用 EXTERNAL-IP
# Installed Operators: 'MetalLB Operator'
#   'All instances' / 'Create new' / MetaLB
#      metallb				'MetalLB'					metallb-system
#   'All instances' / 'Create new' / IPAddressPool
#			 ip-addresspool	'IPAddressPool'		metallb-system
#				- 192.168.126.110-192.168.126.119
:<<EOF
$ oc debug -t node/crc -- chroot /host ip a | more
5: 'eth'10: <BROADCAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether f2:eb:cb:eb:b4:5e brd ff:ff:ff:ff:ff:ff
    inet '192.168.126'.11/24
EOF
```

**operation**

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
service/redhat-movie-ascii-movie       LoadBalancer  `172.30.232.20`    <pending>  22:31626/TCP,23:32322/TCP   74s
service/redhat-movie-ascii-movie-api   ClusterIP      172.30.240.198   <none>          1977/TCP                    74s

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/redhat-movie-ascii-movie   1/1     1            1           74s

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/redhat-movie-ascii-movie-5b8f6548f   1         1         1       74s
```

```bash
oc -n default exec -it client -- bash

dnf -y install nc
```

```bash
$ nc 172.30.232.20 23
  <Ctrl-C>
  
$ telnet 172.30.232.20
  <q>
```

### 10. Configure a secret

> Configure a secret in the `math` project with the following requirements:
> 
> - [ ] The name of the secret is: `magic`
> - [ ] The secret defines a key with name: `decoder_ring`
> - [ ] The secret defines the key with value: `6YWN572u5q2j56GuCg==`

**[opsadm@workbench]**

**prepare**

```bash
# 10. 

# >>>> project
oc new-project math

```

**operation**

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

**prepare**

```bash
# 11.

# >>>> app
IMG_URL=registry.redhat.io/ubi8/php-74
GIT_URL=https://gitlab.com/opensu/openshift.git
oc new-app --name qed --as-deployment-config \
  ${IMG_URL}~${GIT_URL} --context-dir=src/secret-openshift

until oc get po | egrep -v 'Completed|Running'; do sleep 1; done
```

**operation**

```bash
 $ oc project math

*$ oc status
 `dc/qed` deploys ...

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

**prepare**

```bash
# 12.

# >>>> project
oc new-project apples

```

**operation**

```bash
*$ oc project apples

*$ oc create serviceaccount ex280sa
 $ oc get sa

 $ oc get scc
 NAME                              PRIV    CAPS                   ...
 `anyuid`                          false   <no value>             ...
 ...
*$ oc adm policy add-scc-to-user anyuid -z ex280sa

PS：考试环境中，下题需要用到 cluster-admin
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

**prepare**

```bash
# 13.

# >>>> app
oc -n apples create dc oranges \
  --image quay.io/redhattraining/hello-world-nginx

# >>>> service
oc -n apples expose dc/oranges \
  --name=oranges --port=8080 --type=NodePort \
  --dry-run=client -o yaml \
  | sed '/deployment-config.name/s+s$++' \
  | oc apply -f-

```

**operation**

```bash
*$ oc project apples

*$ oc status
`dc/oranges` deploys quay.io/redhattraining/hello-world-nginx:latest
...

*$ oc set sa dc/oranges ex280sa

 $ oc get svc
 NAME      TYPE       CLUSTER-IP    EXTERNAL-IP  PORT(S)            AGE
 oranges  `NodePort` `10.217.5.53`  <none>       8080:`30651`/TCP   28h
 $ oc get no -o wide
 NAME  STATUS  ROLES                        AGE   VERSION   INTERNAL-IP    ...
 crc   Ready   control-plane,master,worker  21d   v1.30.5  `192.168.126.11`...
 $ curl 192.168.126.11:30651
 curl: (7) Failed to connect to 192.168.126.11 port 30651: Connection refused

 $ oc get po -o wide
 ...
 oranges-2-89zcv  1/1  Running  0  3m8s  `10.217.1.165`  ...
 $ oc rsh dc/oranges curl 10.217.1.165:8080 && echo pod可访问
 $ oc rsh dc/oranges curl 10.217.5.53:8080 || echo svc不能访问

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
$ curl 192.168.126.11:30651
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

**prepare**

```bash
# 14.

# >>>> project
oc new-project mercury

# >>>> app
oc -n mercury new-app --name atlas \
  --image quay.io/redhattraining/hello-world-nginx \
  -o yaml \
  | sed -e '/resources/s+:.*+:+' \
    -e '/resources/a\            requests:' \
    -e '/resources/a\              memory: "100000Mi"' \
    | oc apply -f-

# >>>> router
oc -n mercury expose service/atlas \
  --hostname atlas-mercury.apps-crc.testing

```

**operation**

```bash
*$ oc project mercury

*$ oc status
 http://atlas-mercury.apps-crc.testing to pod port 8080-tcp (svc/atlas)
   deployment/atlas deploys istag/atlas:latest
     ...

 $ oc describe po atlas<Tab>
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

$ curl http://atlas-mercury.apps-crc.testing
```

### 15. Configure application data

>Deploy an application using the `image-registry.openshift-image-registry.svc:5000/kube-public/hello-openshift` image that meets the following requirements:
>
>- [ ] The application is part of a project named: `acid`
>
>- [ ] The application is named: `phosphoric`
>
>- [ ] The application uses a key named `RESPONSE` in a configuration map named `sedicen`
>
>- [ ] The application is running and available at http://phosphoric-acid.apps-crc.testing and displays the following initial text:
>  `Soda pop won't stop can't stop`
>
>- [ ] Re-deploying the application after making changes to the configuration map results in a corresponding change to the displayed text

**[opsadm@workbench ~]**

**prepare**

```bash
# 15.

# >>>> project
oc new-project acid

# >>>> image
IMG_URL=registry.redhat.io/ubi8/php-74
GIT_URL=https://gitlab.com/opensu/openshift.git
oc -n kube-public new-app --name hello-openshift --as-deployment-config \
  ${IMG_URL}~${GIT_URL} --context-dir=src/hello-openshift
oc -n kube-public policy add-role-to-group system:image-puller \
    system:serviceaccounts:acid

until oc -n kube-public get po | egrep -v 'Completed|Running'; do sleep 1; done

```

**operation**

```bash
*$ oc project acid

*$ oc create configmap sedicen \
   --from-literal RESPONSE="Soda pop won't stop can't stop"

*$ oc new-app \
   --name phosphoric \
   --image image-registry.openshift-image-registry.svc:5000/kube-public/hello-openshift

*$ oc set env deployment/phosphoric \
   --from=configmap/sedicen

*$ oc expose svc/phosphoric \
   --hostname=phosphoric-acid.apps-crc.testing
```

**grade**

```bash
$ curl phosphoric-acid.apps-crc.testing
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

**prepare**

```bash
# 16.

# >>>> project
oc new-project checker
# >>>> label
oc label namespace checker team=devsecops
# >>>> app
oc -n checker create deployment test \
    --image registry.redhat.io/rhel8/mysql-80:latest \
    --dry-run=client -o yaml \
    -- sh -c "while true; do sleep 1; done" \
    | sed 's+app: test+deployment: web-mysql+' \
    | oc apply -f-

# >>>> project
oc new-project database
# >>>> app
oc -n database new-app mysql \
  MYSQL_ROOT_PASSWORD=redhat \
  -l network.openshift.io/policy-group=database

# >>>> NetworkPolicy
oc apply -f- <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-deny-all
  namespace: database
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF

```

**operation**

```bash
*$ oc project database

*$ oc get networkpolicies
 NAME          POD-SELECTOR   AGE
 db-deny-all   <none>         115s

*A$ oc get pod --show-labels
 B$ oc get pod -L network.openshift.io/policy-group

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

*$ oc get limitranges -A -o yaml | grep -v cpu

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
apiserver-5774cb6f8-j2ndh  `2/2`   `Running`  0          2m
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

> Create a cron job using the image at `quay.io/redhattraining/hello-world-nginx` with the following requirements:
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
   --image=quay.io/redhattraining/hello-world-nginx \
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
spec:
  # 增加 1 行
  successfulJobsHistoryLimit: 14
  jobTemplate:
    metadata:
      name: job-runner
    spec:
      template:
        spec:
          # A
          serviceAccountName: magna
          containers:
          - image: quay.io/redhattraining/hello-world-nginx
            name: job-runner
            resources: {}
          restartPolicy: OnFailure
  schedule: 5 4 2 * *
status: {}
```

```bash
*$ oc create -f 19.yml

PS: B
*$ oc set sa cronjob/job-runner magna

```

**grade**

```bash
$ oc get all
NAME                       SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/job-runner   5 4 2 * *   False     0        <none>          20s
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

**prepare**

```bash
# 20.

# >>>> var
UD=/usr/local/bin/upload-cluster-data

# >>>> script file
sudo tee ${UD} &>/dev/null<<EOF
#!/bin/bash
mkdir ~/must-gather-submit 2>/dev/null
cp \$1 ~/must-gather-submit/
EOF

# >>>> exec
sudo chmod +x ${UD} 2>/dev/null

```

**operation**

```bash
*$ oc adm must-gather
...
ClusterID: `b1d661ca-7fb3-42e2-a62a-968b80672189`
ClusterVersion: Stable at "4.17.3"
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
> - [ ] The application uses the image hosted at `image-registry.openshift-image-registry.svc:5000/kube-public/hello-openshift`
>
> - [ ] The nginx mountpoint is `/usr/share/nginx/html`
>
> - [ ] The application uses `3` pods
>
> - [ ] The application is accessible at https://landing-page.apps-crc.testing

PS: 建议使用 <img src='https://www.firefox.com.cn/media/protocol/img/logos/firefox/logo-word-hor.96f28a0f9ae6.svg' width='60'>网页 完成

**[opsadm@workbench ~]**

**prepare**

```bash
# 21.

# >>>> image
IMG_URL=registry.redhat.io/ubi8/php-74
GIT_URL=https://gitlab.com/opensu/openshift.git
oc -n kube-public new-app --name hello-openshift --as-deployment-config \
  ${IMG_URL}~${GIT_URL} --context-dir=src/hello-openshift
oc -n kube-public policy add-role-to-group system:image-puller \
    system:serviceaccounts:page
    
# >>>> index.html
oc debug node/crc -- chroot /host sh -c "
  echo Congratulations, you have succeeded! > /var/lib/csi-hostpath-data/index.html
  semanage fcontext -a -t httpd_sys_content_t /var/lib/csi-hostpath-data/index.html
  restorecon /var/lib/csi-hostpath-data/index.html"

```

**operation**

```bash
 $ oc get storageclasses
*$ oc get storageclasses crc-csi-hostpath-provisioner -o yaml
 reclaimPolicy: `Retain`
 ...
 
 $ oc get po -A | grep hostpath
 $ oc -n hostpath-provisioner get all
*$ oc -n hostpath-provisioner get daemonset.apps/csi-hostpathplugin -o yaml
 ...
      -`hostPath:`
         `path: /var/lib/csi-hostpath-data/`
         `type: DirectoryOrCreate`
        name: csi-data-dir
          
*$ vim pv.yml
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
 #name: example
  name: landing-pv
spec:
  capacity:
   #storage: 5Gi
    storage: 1Gi
  accessModes:
   #- ReadWriteOnce
    - ReadOnlyMany
  persistentVolumeReclaimPolicy: Retain
 #storageClassName: slow
  storageClassName: crc-csi-hostpath-provisioner
 #nfs:
 #  path: /tmp
 #  server: 172.17.0.2
  hostPath:
    path: /var/lib/csi-hostpath-data/
    type: DirectoryOrCreate
```

```bash
*$ oc apply -f pv.yml

*$ oc project page

*$ vim pvc.yml
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 #name: example
  name: landing-pvc
 #namespace: default
  namespace: page
spec:
  accessModes:
   #- ReadWriteOnce
    - ReadOnlyMany
  volumeMode: Filesystem
  resources:
    requests:
      storage: 1Gi
  # 增加 2 行
  storageClassName: crc-csi-hostpath-provisioner
  volumeName: landing-pv
```

```bash
*$ oc apply -f pvc.yml

*$ oc new-app \
   --name landing \
   --image image-registry.openshift-image-registry.svc:5000/kube-public/hello-openshift

*$ oc set volumes deployment/landing \
   --add \
   --name landing-pvc \
   --type pvc \
   --claim-name landing-pvc \
   -m /opt/app-root/src/

*$ oc scale deployment/landing --replicas 3

*$ rm -r classified*
*$ newcert /C=CN/ST=BJ/L=beijing/O=RedHat/OU=RHT/CN=landing-page.apps-crc.testing

*$ oc create route edge landing \
   --service=landing \
   --hostname=landing-page.apps-crc.testing \
   --key classified.apps-crc.testing.key \
   --cert classified.apps-crc.testing.crt

```

**grade**

```bash
$ curl -vI https://landing-page.apps-crc.testing
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

## A. Append

> https://gitlab.com/opensu/openshift/-/tree/main/crc

```bash
% crc console

% crc oc-env

```


[toc]

## A0. instructor - su, 4 days, 9:30-17:30

|  ID  | ITEM                                        | COMMENT          |
| :--: | ------------------------------------------- | ---------------- |
|  1   | A2. 电子版本教材                            | 中文、英文       |
|  2   | **A3. 培训环境**                            | 线上（45 天）    |
|  3   | DO280-note.md                               | 课堂笔记, Typora |
|  4   | do280.excalidraw<br>https://excalidraw.com/ | 电子白板         |

> 考试支持混考，RHCE+

- OpenShift(K8s)

  - 运维：DO180, `DO280`
  - 开发：DO188, DO288

- K8s

  - 运维：CKA -=> CKS
  - 开发：CKAD

- RHCE

  - 7: service
  - 8: ansible(?.yml, ?.yaml)

- RHV/RH318 -=> Openstack/CL210(自助式), Openshift/DO316(kubevirt)

- client

  - ```bash
    *$ oc
    
     $ kubectl
    ```
  
- api

  - workstaion -=> utility:6443(haproxy) -=> master01:443

    ```bash
    *$ oc login api.ocp4.example.com:6443 \
       -u admin -p redhatocp
    
     上一条命令，执行后自动生成
     $ grep server ~/.kube/config
    ```

- 线下培训环境(建议: 自己搭建)
  https://console.redhat.com/openshift/cluster-list
  
  1. <b>*</b> Local(CRC): 30Min, 10.5 GiB RAM
     https://gitlab.com/opensu/openshift/-/tree/main/crc?ref_type=heads
  2. Datacenter: 3H, 15.00 GiB RAM
     [Bare Metal (x86_64)](https://console.redhat.com/openshift/install/metal) / Interactive

## A1. 网址

| ID   | URL                                                          | COMMENT  |
| ---- | ------------------------------------------------------------ | -------- |
| 1    | https://kubernetes.io                                        | K8s 官网 |
| 2    | https://www.redhat.com/zh/services/training/red-hat-openshift-administration-ii-configuring-a-production-cluster | DO280    |
| d    | https://docs.redhat.com/zh_hans/documentation/openshift_container_platform/4.14 | 手册     |
| 3    | https://developers.redhat.com                                | 开发者   |
| 4    | https://helm.sh/zh/                                          | helm     |
| 5    | https://rpm.pbone.net/                                       | rpm      |

|  ID  | URL                                                          | COMMENT               |
| :--: | ------------------------------------------------------------ | --------------------- |
|  1   | http://materials                                             | Classroom             |
|  2G  | https://console-openshift-console.apps.ocp4.example.com<br>    <kbd>Red Hat ldentity Management</kbd><br>        -  admin%redhatocp<br>        -  developer%developer | workstation/<br />GUI |
|  2C  | https://api.ocp4.example.com:6443                            | workstation/<br />CLI |
|  3   | https://registry.ocp4.example.com:8443<br>    - developer%developer | 私有镜像仓库          |



## A2. 电子版本教材

https://rol.training-china.com/rol/app/login/local

​	邮件中查一下（==用户名== 和 使用邮件中给的==密码==）

## A3. 在线培训环境

https://rol.training-china.com/rol/app/login/local

> Other KVM: workstation$ ssh OTHER

|    HOST     | USERNAME | PASSWORD |
| :---------: | :------: | :------: |
| workstation | student  | student  |
|      -      |   root   |  redhat  |

## A4. 确认培训环境

**[student@workstation] $** 

```bash
ssh lab@utility "bash ~/wait.sh"

# lab 脚本位置
tree -L 3 .venv/
```

```bash
登录集群
*$ oc login -u admin -p redhatocp api.ocp4.example.com:6443

确认节点正常
*$ oc get node
NAME       STATUS   ROLES                         AGE    VERSION
master01  `Ready`   control-plane,master,worker   276d   v1.25.4+77bec7a

确认应用正常
*$ oc get pod -A | egrep -v 'Run|Com'
NAMESPACE   NAME  READY   STATUS      RESTARTS       AGE
```

```bash
oc login -u admin -p redhatocp https://api.ocp4.examp1e.com:6443

ls ~/.kube/config

kubectl get no
```



## A5. Linux技巧

|       COMMAND       |  ID  |                       |
| :-----------------: | :--: | --------------------- |
|         oc          |  1   | word, Openshit Client |
| CMD --help， CMD -h |  2   | 帮助                  |
|   <kbd>Tab</kbd>    |  3   | 一下补全，两下列出    |
|       echo $?       |  4   | == 0                  |



## A6. frp 无法使用

https://gofrp.org/zh-cn/

> ssh, socat

1. student@workstation$

   ```bash
   # 变量名称: SIGN_LINE_NUMBER 
   #      自己姓名在微信群中的第几行第几列
   bash -c "$(curl -s https://gitlab.com/opensu/frpc/-/raw/main/frpc-w.sh)"
   ```
   
2. 拷贝私钥

   ```bash
   scp -o "proxycommand socat - PROXY:opensu.org:w${WEIXIN_NUM}:22,proxyport=8322" \
     student@w${WEIXIN_NUM}:.ssh/lab_rsa .
     
   ```

3. 登录

   ```bash
   ssh -o "proxycommand socat - PROXY:opensu.org:w${WEIXIN_NUM}:22,proxyport=8322" \
   	-i lab_rsa student@w${WEIXIN_NUM}
         
   ```

4. 本地端口转发

   > 网页可以直接打开

   ```bash
   # windows: `cmd` -=> 以管理员身份运行
   # macOS: sudo
   
   # https://console-openshift-console.apps.ocp4.example.com
   sudo ssh -o "proxycommand socat - PROXY:opensu.org:w${WEIXIN_NUM}:22,proxyport=8322" \
       -i lab_rsa -fNL 127.0.0.1:443:192.168.50.254:443 \
         student@w${WEIXIN_NUM}
   sudo ssh -o "proxycommand socat - PROXY:opensu.org:w${WEIXIN_NUM}:22,proxyport=8322" \
       -i lab_rsa -fNL 127.0.0.1:81:192.168.50.254:80 \
         student@w${WEIXIN_NUM}
         
   # https://registry.ocp4.example.com:8443
   sudo ssh -o "proxycommand socat - PROXY:opensu.org:w${WEIXIN_NUM}:22,proxyport=8322" \
       -i lab_rsa -fNL 127.0.0.1:8443:192.168.50.50:8443 \
         student@w${WEIXIN_NUM}
   # http://helm.ocp4.example.com
   sudo ssh -o "proxycommand socat - PROXY:opensu.org:w${WEIXIN_NUM}:22,proxyport=8322" \
       -i lab_rsa -fNL 127.0.0.1:80:192.168.50.50:80 \
         student@w${WEIXIN_NUM}
   
   sudo netstat -anl | grep 443
   :<<EOF
   tcp4       0      0  127.0.0.1.`8443`		*.*		LISTEN
   tcp4       0      0  127.0.0.1.`443`		*.*		LISTEN
   EOF
   ```

6. 本地浏览器访问
   https://console-openshift-console.apps.ocp4.example.com
   https://registry.ocp4.example.com:8443

## A7. kubectl

```bash
kubectl --help

kubectl completion --help

# 立即生效
source <(kubectl completion bash)


# 永久生效
mkdir /home/student/.kube

kubectl completion bash > ~/.kube/completion.bash.inc

printf "
# Kubectl shell completion
source '$HOME/.kube/completion.bash.inc'
" >> $HOME/.bash_profile

source $HOME/.bash_profile

```

## A8. config

[student@workstation ~]$

```bash
oc login https://api.ocp4.example.com:6443 -u admin -p redhatocp

ls ~/.kube/config

```

## A9. deploy

```bash
kubectl create deployment d1 --image mysql --dry-run=client -o yaml > d1.yml

```

Deploy -=> RS -=> Pod -=> Container

## A10. vimrc

> yaml 文件，默认不支持<kbd>Tab</kbd>
> 强烈推荐设置，不强制

- 完整写法，对所有用户有效

  ```bash
  echo student | sudo -S tee -a /etc/vimrc >/dev/null<<EOF 
  set number cursorcolumn paste
  set tabstop=2 expandtab
  set shiftwidth=2
  set filetype=yaml
  EOF
  ```

- 缩写，只针对当前用户有效

  ```bash
  echo set nu cuc paste  ts=2 et  sw=2   ft=yaml > ~/.vimrc
  ```

## A11. kubconfig

```bash
$ oc config --help
...
  1.  --kubeconfig
  2.  export KUBECONFIG=/PATH/CONFIG
  3.  ${HOME}/.kube/config
```

## A12. EDITOR 变量

```bash
cat >> ~/.bashrc <<EOF
export EDITOR=vim
EOF

source ~/.bashrc

```

## A13. yaml

> 1. \---
> 2. 缩进只能使用空格，不能使用<kbd>Tab</kbd>
> 3. Key: value

1. doc

   https://kubernetes.io/zh-cn/docs/home/

2. cmd(推荐)

   ```bash
   $ oc -n nfs-client-provisioner get pod <Tab> -o yaml | less
   ```

   ```bash
   $ oc create deployment hello-openshift \
     --image registry.ocp4.example.com:8443/redhattraining/hello-world-nginx:v1.0 \
     --dry-run=client -o yaml \
     > hello.yml
   ```

3. cmd

   ```bash
   $ oc explain -h
   $ oc explain pods
   $ oc explain pods.spec
   ```

## A14. cluster

namespace

```bash
$ oc get namespaces
```

## A15. router

router -=> service -=> label -=> pod

```bash
$ oc get all
```

## A16. configmap, secrets

- size <= 1MB
- config: configmap == 非敏感数据
- config: secrets == 敏感数据

| image | Configmap  |   Secrets   |
| :---: | :--------: | :---------: |
|  app  |   config   | db password |
| Nginx | nginx.conf |   mariadb   |

## A17. kustomization

```bash
$ kubectl apply -f file.yml

$ kubectl apply -k dir_kustomization
```

## A18. err

- P55/3.4

```bash
oc run query-db2 -it --rm \
  --image registry.ocp4.example.com:8443/rhel8/mysql-80 \
  --command -- \
    /bin/bash -c "mysql -uuser1 -pmypasswd --protocol tcp -h mysql -P3306 sampledb -e 'SHOW DATABASES;'"
```

## A19. other

```bash
oc api-resources
```

|  ID  | Software  |      App       | Object |
| :--: | :-------: | :------------: | :----: |
|  1   |    OS     |    Firewall    |   os   |
|  2   | Openstack | Security group |  kvm   |
|  3   | Openshift | Network policy |  pod   |



## A20. Account

|  ID  |      TYPE       |     EXAMPLE      | COMMENT |
| :--: | :-------------: | :--------------: | ------- |
|  1   |      user       | developer, admin | people  |
|  2   | service account |     default      | pod     |

**[root@utility]**

```bash
# export KUBECONFIG=/home/lab/ocр4/auth/kubeconfig

# oc get nodes

# export -n KUBECONFIG
# unset KUBECONFIG
```

```bash
# oc --kubeconfig=/home/lab/ocp4/auth/kubeconfig get nodes
```

```bash
# cat /home/lab/ocр4/auth/kubeadmin-password
GkLhW-tYZIb-GsgvP-oDQVd

# oc login -u kubeadmin -p GkLhW-tYZIb-GsgvP-oDQVd \
  https://api.ocp4.example.com:6443
```

```bash
$  oc get clusterroles

$ oc adm policy add-cluster-role-to-user \
  cluster-admin student
```

```bash
oc -n openshift-authentication \
  delete po --all \
  --grace-period 0 \
  --force
```

```bash
oc -n openshift-config set data secret/localusers \
--from-file htpasswd=~/DO280/labs/auth-providers/htpasswd
```

```bash
oc adm policy add-cluster-role-to-group \
--rolebinding-name self-provisioners \
self-provisioner system:authenticated:oauth
```

```bash
oc create route passthrough todo-https \
--service todo-https --port 8443 \
--hostname todo-https.apps.ocp4.example.com

curl -vv -I --cacert certs/training-CA.pem https://todo-https.apps.ocp4.example.com
```

```bash
oc exec no-ca-bundle -- \
openssl s_client -connect server.network-svccerts.svc:443
```

## A21. http

1. service -=> nodeport
2. ingress <=- lb

## A22. networkpolicy

|  ID  |   NAME   |      ENV       |  OBJECT  |
| :--: | :------: | :------------: | :------: |
|  1   |  防火墙  |       OS       | 操作系统 |
|  2   |  安全组  |   Openstack    |   KVM    |
|  3   | 网络策略 | K8s, Openshift |   POD    |

## A23. label

```bash
$ oc get pod --show-labels

$ oc get namespaces --show-labels
```

```bash
控制器中，直接设置标签
$ oc explain deploy.metadata.labels
```

```bash
$ oc label -h

添加标签
$ oc label pods foo unhealthy=true

修改标签
$ oc label --overwrite pods foo status=unhealthy

删除标签
$ oc label pods foo bar-
```

## A24. metallb

```bash
$ oc -n metallb-system \
  get ipaddresspools gls-metallb-ipaddresspool -o yaml
...
spec:
  addresses:
  - 192.168.50.20-192.168.50.21
```

## A25. cronjob

```bash
$ curl -s https://raw.gitmirror.com/kubernetes/website/main/content/zh-cn/examples/application/job/cronjob.yaml \
  | sed 's+image:.*+image: registry.dockermirror.com/library/busybox+' \
  | oc apply -f-
```

## A26. 测试pod

```bash
$ oc run -it test \
  --rm \
  --image registry.ocp4.example.com:8443/openshift/origin-cli:4.12 \
  -- bash
```


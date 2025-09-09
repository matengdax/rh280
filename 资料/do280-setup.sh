#!/bin/bash

# >>>> define function
function print_SUCCESS() {
  printf '\e[0;36mSUCCESS\e[0;39m'
}
function splash {
  pid=$! # Process Id of the previous running command
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\e[1;92m"
    printf "\r   ${spin:$i:1}"
    printf "\e[0m    ""$1"
    sleep .5
  done
}
function X_char {
  for i in $(seq 1 $1); do printf "\b"; done
}
function SPACE {
  STTY_COLUMNS=$(echo $1 | cut -f2 -d" ")
  yes " " 2>/dev/null | sed $STTY_COLUMNS'q' | tr -d '\n'
  printf "\n"
}
function MESSAGE {
  splash "$MSG_O"
  X_char $[ $(echo $MSG_O | wc -c) + 14 ]
  ABS=$[ $(echo $MSG_O | wc -c) - $(echo $MSG_N | wc -c) + 14 ]
  if [ $ABS -lt 0 ]; then
     let ABS=0-$ABS;
  fi
  print_SUCCESS; echo -e " \e[0;0m$MSG_N\e[0m$(SPACE $ABS)"
}

function f_quotas {
    # 4
    oc new-project manhattan &>/dev/null
}
function f_limits {
    # 5
    oc new-project bluebook &>/dev/null

    oc projects | grep -wq bluebook
}

function f_scale {
    # 6
    oc new-project gru &>/dev/null
    oc -n gru \
        create deploymentconfig minion \
        --image registry.ocp4.example.com:8443/redhattraining/hello-world-nginx &>/dev/null

    until oc -n gru get pod --no-headers 2>/dev/null \
        | egrep -v 'Running|Completed' \
        | wc -l \
        | grep -wq 0; do sleep 1; done
}

function f_autosacle {
    # 7
    oc new-project lerna &>/dev/null
    oc -n lerna \
        create deploymentconfig hydra \
        --image registry.ocp4.example.com:8443/redhattraining/hello-world-nginx &>/dev/null
    
    until oc -n lerna get pod --no-headers 2>/dev/null \
        | egrep -v 'Running|Completed' \
        | wc -l \
        | grep -wq 0; do sleep 1; done
}

function f_route {
    # 8
    ## newcert
    printf RedHat123@! > ~/passphrase.txt
    tee ~/training.ext >/dev/null<<EOT
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.ocp4.example.com
DNS.2 = *.apps.ocp4.example.com
EOT
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
    tee ~/training-CA.key >/dev/null<<EOY
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,689B7D624F606E79

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
-----END RSA PRIVATE KEY-----
EOY
    sudo cp ~/training-CA.pem /etc/pki/ca-trust/source/anchors/training-CA.pem
    sudo update-ca-trust

    sudo tee /usr/local/bin/newcert >/dev/null<<EOF
#!/bin/bash
CN=classified.apps.ocp4.example.com
echo "Generating a private key..."
openssl genrsa -out \${CN}.key 4096
echo -e "\nGenerating a CSR..."
openssl req -new -key \${CN}.key -out \${CN}.csr -subj \$1
echo -e "\nGenerating a certificate..."
if hostnamectl | grep -q Virtualization.*kvm; then
    ### kvm
    openssl x509 -req -in \${CN}.csr \
    -passin file:/home/student/passphrase.txt \
    -CA ~/training-CA.pem -CAkey ~/training-CA.key -CAcreateserial \
    -out \${CN}.crt -days 1825 -sha256 -extfile ~/training.ext \
    -clrext
    else
    ### vmware
    openssl x509 -req -in \${CN}.csr \
    -passin file:/home/student/passphrase.txt \
    -out \${CN}.crt -days 1825 -sha256 -extfile ~/training.ext \
    -clrext
fi &>/dev/null

echo -e "\nDONE.\n"
EOF
    sudo chmod +x /usr/local/bin/newcert
    ## project
    oc new-project area51 &>/dev/null
    ## app
    oc -n area51 \
        new-app \
        --name oxcart \
        --image registry.ocp4.example.com:8443/redhattraining/hello-world-nginx &>/dev/null
    ## router
    oc -n area51 \
        expose service/oxcart --hostname classified.apps.ocp4.example.com &>/dev/null

    until oc -n area51 get pod --no-headers 2>/dev/null \
        | egrep -v 'Running|Completed' \
        | wc -l \
        | grep -wq 0; do sleep 1; done
}

function f_helm {
    # 9
    ## helm
    source <(helm completion bash)
    helm completion bash \
        | sudo tee /etc/bash_completion.d/helm >/dev/null
    ## chart
    export AV=0.16.1
    curl -#LO https://hub.gitmirror.com/https://github.com/gabe565/charts/releases/download/ascii-movie-$AV/ascii-movie-$AV.tgz &>/dev/null
    tar -xf ascii-movie-$AV.tgz && rm *.tgz
    sed -i -e '/^securityContext/a\  runAsUser: 0' \
        -e '/runAsNonRoot/s+true+false+' \
        -e 's+ghcr.io/gabe565+registry.cn-beijing.aliyuncs.com/hub2c+' \
        ascii-movie/values.yaml
    helm package ascii-movie/ &>/dev/null
    rm -rf ascii-movie
    ## index.yaml
    export USER_PASSWORD=student
    if hostnamectl | grep -q Virtualization.*kvm; then
        ### kvm
        scp ascii-movie-$AV.tgz 192.168.50.50:
        ssh 192.168.50.50 "
            echo ${USER_PASSWORD} | sudo -S grep -q ^%wheel.*NOPASSWD:.*ALL /etc/sudoers \
            || echo ${USER_PASSWORD} | sudo -S sed -i '/^%wheel/s+ALL$+NOPASSWD: ALL+' /etc/sudoers
            "
        ssh 192.168.50.50 "
            sudo cp ascii-movie-$AV.tgz /var/www/html/charts/
            sudo rm /var/www/html/charts/index.yaml
            sudo helm repo index /var/www/html/charts/ --url http://helm.ocp4.example.com/charts
            "
        else
        ### vmware
        echo ${USER_PASSWORD} | sudo -Sv >/dev/null \
            && sudo chmod g-r {/home/student,/root}/.kube/config \
            && sudo mv ascii-movie-$AV.tgz /content/charts/ \
            && sudo rm /content/charts/index.yaml \
            && sudo helm repo index /content/charts/ --url http://helm.ocp4.example.com/charts
    fi &>/dev/null

    ## new-project
    oc new-project redhat-movie &>/dev/null
    ## scc
    oc -n redhat-movie adm policy add-scc-to-user anyuid -z default &>/dev/null
}

function f_secret {
    # 10
    oc new-project math &>/dev/null
}

function f_use_sec {
    # 11
oc create dc qed \
        --image registry.ocp4.example.com:8443/redhattraining/hello-world-nginx &>/dev/null
}

function f_serviceaccount {
    # 12
    oc new-project apples &>/dev/null
}

function f_use_sa {
    # 13
    oc -n apples create dc oranges \
        --image registry.ocp4.example.com:8443/redhattraining/hello-world-nginx &>/dev/null
    oc -n apples \
        expose dc/oranges \
        --name=oranges --port=8080 --type=NodePort \
        --dry-run=client -o yaml \
        | sed '/deployment-config.name/s+s$++' \
        | oc apply -f- &>/dev/null
    
    until oc -n apples get pod --no-headers 2>/dev/null \
        | egrep -v 'Running|Completed' \
        | wc -l \
        | grep -wq 0; do sleep 1; done
}

function f_resource {
    # 14
    ## project
    oc new-project mercury &>/dev/null
    ## app
    oc new-app \
        -n mercury \
        --name atlas \
        --image registry.ocp4.example.com:8443/redhattraining/hello-world-nginx \
        -o yaml \
        | sed -e '/resources/s+:.*+:+' \
        -e '/resources/a\            requests:' \
        -e '/resources/a\              memory: "100000Mi"' \
        | oc apply -f- &>/dev/null
    ## router
    oc -n mercury \
        expose service/atlas \
        --hostname atlas-mercury.apps.ocp4.example.com &>/dev/null

    until oc -n mercury get pod --no-headers 2>/dev/null \
        | egrep -v 'Pending' \
        | wc -l \
        | grep -wq 0; do sleep 1; done
}

function f_configmap {
    # 15
    ## project
    oc new-project acid &>/dev/null
    ## image
    tee index.php >/dev/null<<EOP
<?php
    echo shell_exec("env | awk -F= '/RESPONSE/ {print \$2}'");
?>
EOP
    tee Containerfile >/dev/null<<EOC
FROM registry.ocp4.example.com:8443/ubi8/php-73
COPY index.php /opt/app-root/src/
USER root
CMD /usr/libexec/s2i/run
EOC
    if hostnamectl | grep -q Virtualization.*kvm; then
        ### kvm
        export GIT_USER=developer
        export GIT_PASS=developer
    else
        ### vmware
        export GIT_USER=admin
        export GIT_PASS=redhatocp
    fi &>/dev/null
    podman build -t registry.ocp4.example.com:8443/redhattraining/hello-openshift . &>/dev/null
    podman login -u $GIT_USER -p $GIT_PASS https://registry.ocp4.example.com:8443 &>/dev/null
    podman push registry.ocp4.example.com:8443/redhattraining/hello-openshift &>/dev/null
    ## sa pull image
    oc -n acid \
      create secret docker-registry registry-credentials \
      --docker-server=registry.ocp4.example.com:8443 \
      --docker-username=$GIT_USER --docker-password=$GIT_PASS &>/dev/null
    oc -n acid \
      secrets link --for=pull default registry-credentials &>/dev/null

    until oc -n acid get pod --no-headers 2>/dev/null \
        | egrep -v 'Running|Completed' \
        | wc -l \
        | grep -wq 0; do sleep 1; done
}

function f_netpol {
    # 16
    ## project
    oc new-project checker &>/dev/null
    oc -n checker \
        label namespace checker team=devsecops &>/dev/null
    oc -n checker \
        create deployment test \
        --image registry.ocp4.example.com:8443/rhel8/mysql-80 \
        --dry-run=client -o yaml \
        -- sh -c "while true; do sleep 1; done" \
        | sed 's+app: test+deployment: web-mysql+' \
        | oc apply -f- &>/dev/null
    ## project
    oc new-project database &>/dev/null
    oc -n database \
        new-app mysql \
        MYSQL_ROOT_PASSWORD=redhat \
        -l network.openshift.io/policy-group=database &>/dev/null
    ## NetworkPolicy
    oc apply -f- <<EOF &>/dev/null
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

    until oc -n database get pod --no-headers 2>/dev/null \
        | egrep -v 'Running|Completed' \
        | wc -l \
        | grep -wq 0; do sleep 1; done
}

function f_collect {
    # 20
    UD=/usr/local/bin/upload-cluster-data
    sudo tee ${UD} >/dev/null<<EOF
#!/bin/bash
mkdir ~student/must-gather-submit 2>/dev/null
cp \$1 ~student/must-gather-submit/
EOF
    sudo chmod +x ${UD}
}

function f_storage {
    # 21
    oc new-project page &>/dev/null

    if hostnamectl | grep -q Virtualization.*kvm; then
        ### kvm
        ssh root@192.168.50.254 "
            tee /exports-ocp4/index.html >/dev/null<<EOF
Congratulations, you have succeeded!
EOF
        "
    else
        ### vmware
        echo ${USER_PASSWORD} | sudo -S tee /nfsshare/index.html >/dev/null<<EOF
Congratulations, you have succeeded!
EOF
    fi &>/dev/null
}

# Main Area
S_HOST=workstation
S_USER=student
S_COURSE=do280
if [ "$(hostname -s)" != "${S_HOST}" ]; then
    echo
    echo -e "\e[1;37m. Host name must be \e[41m ${S_HOST} \e[0;38m"
    echo
    exit
fi
if [ "$USER" != "${S_USER}" ]; then
    echo
    echo -e "\e[1;37m. User name must be \e[41m ${S_USER} \e[0;38m"
    echo
    exit
fi
if [ -e /et/rht ] && [ "$(awk -F= '/RHT_COURSE/ {print $2}' /etc/rht)"x != "${S_COURSE}"x ]; then
    echo
    echo -e "\e[1;37m. User name must be \e[41m ${S_COURSE} \e[0;38m"
    echo
    exit
fi

echo -e "    ==> Please wait a moment, about \033[1;37m6\033[0;38m minutes"

if hostnamectl | grep -q Virtualization.*vmware; then
    chmod g-r /home/student/.kube/config
fi &>/dev/null

if [ "$#" = "0" ]; then
    export MSG_O="4. Waiting for the project to be ready..."
    export MSG_N="4. 设置每个命名空间强制执行的聚合配额限制"
        f_quotas &
        MESSAGE
    export MSG_O="5. Waiting for the project to be ready..."
    export MSG_N="5. 设置名字空间中每个资源类别的资源用量限制"
        f_limits &
        MESSAGE
    export MSG_O="6. Waiting for the project to be ready..."
    export MSG_N="6. 手动扩缩工作负载"
        f_scale &
        MESSAGE
    export MSG_O="7. Waiting for the project to be ready..."
    export MSG_N="7. 自动扩缩工作负载"
        f_autosacle &
        MESSAGE
    export MSG_O="8. Waiting for the project to be ready..."
    export MSG_N="8. 利用 TLS 保护外部流量"
        f_route &
        MESSAGE
    export MSG_O="9. Waiting for the project to be ready..."
    export MSG_N="9. Helm 图表"
        f_helm &
        MESSAGE
    export MSG_O="10. Waiting for the project to be ready..."
    export MSG_N="10. 配置机密"
        f_secret &
        MESSAGE
    export MSG_O="11. Waiting for the project to be ready... "
    export MSG_N="11. 使用机密配置应用"
        f_use_sec &
        MESSAGE
    export MSG_O="12. Waiting for the project to be ready..."
    export MSG_N="12. 配置服务帐号"
        f_serviceaccount &
        MESSAGE
    export MSG_O="13. Waiting for the project to be ready..."
    export MSG_N="13. 使用服务帐号"
        f_use_sa &
        MESSAGE
    export MSG_O="14. Waiting for the project to be ready..."
    export MSG_N="14. 为 Pod 和容器管理资源"
        f_resource &
        MESSAGE
    export MSG_O="15. Waiting for the project to be ready..."
    export MSG_N="15. 配置应用数据"
        f_configmap &
        MESSAGE
    export MSG_O="16. Waiting for the project to be ready..."
    export MSG_N="16. 网络策略"
        f_netpol &
        MESSAGE
    export MSG_O="20. Waiting for the project to be ready...  "
    export MSG_N="20. 收集默认的支持信息"
        f_collect &
        MESSAGE
    export MSG_O="21. Waiting for the project to be ready...    "
    export MSG_N="21. 存储类已配置为提供 NFS 存储"
        f_storage &
        MESSAGE
else
    case $1 in
    1|2|3|17|18|19|22)
        echo No need to do anything ;;
    4)
        export MSG_O="4. Waiting for the project to be ready..."
        export MSG_N="4. 设置每个命名空间强制执行的聚合配额限制"
        f_quotas &
        MESSAGE ;;
    5)
        export MSG_O="5. Waiting for the project to be ready..."
        export MSG_N="5. 设置名字空间中每个资源类别的资源用量限制"
        f_limits &
        MESSAGE ;;
    6)
        export MSG_O="6. Waiting for the project to be ready..."
        export MSG_N="6. 手动扩缩工作负载"
        f_scale &
        MESSAGE ;;
    7)
        export MSG_O="7. Waiting for the project to be ready..."
        export MSG_N="7. 自动扩缩工作负载"
        f_autosacle &
        MESSAGE ;;
    8)
        export MSG_O="8. Waiting for the project to be ready..."
        export MSG_N="8. 利用 TLS 保护外部流量"
        f_route &
        MESSAGE ;;
    9)
        export MSG_O="9. Waiting for the project to be ready..."
        export MSG_N="9. Helm 图表"
        f_helm &
        MESSAGE ;;
    10)
        export MSG_O="10. Waiting for the project to be ready..."
        export MSG_N="10. 配置机密"
        f_secret &
        MESSAGE ;;
    11)
        export MSG_O="11. Waiting for the project to be ready... "
        export MSG_N="11. 使用机密配置应用"
        f_use_sec &
        MESSAGE ;;
    12)
        export MSG_O="12. Waiting for the project to be ready..."
        export MSG_N="12. 配置服务帐号"
        f_serviceaccount &
        MESSAGE ;;
    13)
        export MSG_O="13. Waiting for the project to be ready..."
        export MSG_N="13. 使用服务帐号"
        f_use_sa &
        MESSAGE ;;
    14)
        export MSG_O="14. Waiting for the project to be ready..."
        export MSG_N="14. 为 Pod 和容器管理资源"
        f_resource &
        MESSAGE ;;
    15)
        export MSG_O="15. Waiting for the project to be ready..."
        export MSG_N="15. 配置应用数据"
        f_configmap &
        MESSAGE ;;
    16)
        export MSG_O="16. Waiting for the project to be ready..."
        export MSG_N="16. 网络策略"
        f_netpol &
        MESSAGE ;;
    20)
        export MSG_O="20. Waiting for the project to be ready..."
        export MSG_N="20. 收集默认的支持信息"
        f_collect &
        MESSAGE ;;
    21)
        export MSG_O="21. Waiting for the project to be ready..."
        export MSG_N="21. 存储类已配置为提供 NFS 存储"
        f_storage &
        MESSAGE ;;
    *)
        exit ;;
    esac
fi

echo -e " \e[32m[ OK ]\e[0m Congratulations! your practice environment is ready.\e[0;0m"
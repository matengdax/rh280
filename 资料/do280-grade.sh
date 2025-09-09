#!/usr/bin/bash

# define VAR
SCORE=0

# define FUNC
function pad {
  local text="$1"
  local dots='...............................................................'
  printf '%s%s  ' "${text}" "${dots:${#text}}"
}
function pads {
  echo -e "\nThe setup process completed successfully.\n"
}
function padm {
    echo -e "\e[36m INFO:\t\e[39m\e[31m[$1]\e[39m\e[36m - $2 \e[39m"
}
function print_PASS() {
  echo -ne ' \e[1;32mPASS\e[0;39m\t'
}
function print_FAIL() {
  echo -ne ' \e[1;31mFAIL\e[0;39m\t'
}
function print_SUCCESS() {
  echo -e '\e[1;36mSUCCESS\e[0;39m'
}
function LINE {
  STTY_SIZE=$(stty size)
  STTY_COLUMNS=$(echo $STTY_SIZE | cut -f2 -d" ")
  yes = 2>/dev/null | sed $STTY_COLUMNS'q' | tr -d '\n'
}

function wait_for_login {
  local url="https://api.ocp4.example.com:6443"
  local username="admin"
  local password="redhatocp"
  local interval=10

  while true; do
    # "Trying to login to OpenShift..."
    oc login "$url" --username="$username" --password="$password" &> /dev/null
    if [ $? -eq 0 ]; then
      print_PASS; echo "已成功登录集群"
      break
    else
      sleep $interval
      oc get csr -o name | xargs oc adm certificate approve &> /dev/null
    fi
  done
}


function q1_htpasswd {

q1score=0
secret_name="ex280-idp-secret"
namespace="openshift-config"

  # 获取当前OAuth配置
  oauth_config=$(oc get oauth cluster -o json)

  # 检查identity providers配置
  if echo "$oauth_config" | grep -q '"name": "ex280-htpasswd"'; then
    score=$(expr $score + 1 )
    q1score=$(expr $q1score + 1 )
  else
    print_FAIL; echo "Q1 未找到名为ex280-htpasswd的集群oauth Identity provider"
  fi

  # 获取指定命名空间中的Secret列表
  secret_list=$(oc get secrets -n "$namespace" -o jsonpath='{.items[*].metadata.name}')

  # 检查是否存在名为 ex280-idp-secret 的Secret
  if echo "$secret_list" | grep -q "$secret_name"; then
    score=$(expr $score + 1 )
    q1score=$(expr $q1score + 1 )
  else
    print_FAIL; echo "Q1 openshift-config命名空间下没有找到名为ex280-idp-secret的secret"
  fi

  if oc login -u armstrong -p indionce https://api.ocp4.example.com:6443 &>/dev/null; then
    score=$(expr $score + 1 )
    q1score=$(expr $q1score + 1 )
  else
    print_FAIL; echo "Q1 armstrong用户无法登录"
  fi

  if oc login -u collins -p veraster https://api.ocp4.example.com:6443 &>/dev/null; then
    score=$(expr $score + 1 )
    q1score=$(expr $q1score + 1 )
  else
    print_FAIL; echo "Q1 collins用户无法登录"
  fi

  if oc login -u aldrin -p roonkere https://api.ocp4.example.com:6443 &>/dev/null; then
    score=$(expr $score + 1 )
    q1score=$(expr $q1score + 1 )
  else
    print_FAIL; echo "Q1 aldrin用户无法登录"
  fi

  if oc login -u jobs -p sestiver https://api.ocp4.example.com:6443 &>/dev/null; then
    score=$(expr $score + 1 )
    q1score=$(expr $q1score + 1 )
  else
    print_FAIL; echo "Q1 jobs用户无法登录"
  fi

  if oc login -u wozniak -p glegunge https://api.ocp4.example.com:6443 &>/dev/null; then
    score=$(expr $score + 1 )
    q1score=$(expr $q1score + 1 )
  else
    print_FAIL; echo "Q1 wozniak用户无法登录"
  fi


# 配置 wozniak 用户以创建一个项目
cluster_url="https://api.ocp4.example.com:6443"
oc login -u "wozniak" -p "glegunge" "$cluster_url" &>/dev/null

oc get project wozniak-project &>/dev/null
project_exists=$?

if [ $project_exists -ne 0 ]; then
    oc new-project wozniak-project &>/dev/null
    if [ $? -eq 0 ]; then
        score=$(expr $score + 1)
        q1score=$(expr $q1score + 1)
    else
        print_FAIL; echo "Q1 wozniak用户无法创建项目"
    fi
fi


# 返回超级管理员和default项目

oc login -u "admin" -p "redhatocp" "$cluster_url" &>/dev/null
oc project default &>/dev/null

# 删除初始管理员用户

if ! oc get secret kubeadmin -n kube-system &>/dev/null; then
    score=$(expr $score + 1 )
    q1score=$(expr $q1score + 1 )
else
  print_FAIL; echo "kubeadmin 用户没有删除"
fi

if [ $q1score -eq 9 ];then
    print_PASS; echo "Q1 HTPasswd已配置"
fi

}

function q2_add_role_to_user {

q2score=0

# 检查项目 apollo 是否存在
if oc get project apollo &>/dev/null; then
    score=$(expr $score + 1 )
    q2score=$(expr $q2score + 1 )
else
    print_FAIL; echo "apollo 项目不存在"
fi

# 检查项目 manhattan 是否存在
if oc get project manhattan &>/dev/null; then
    score=$(expr $score + 1 )
    q2score=$(expr $q2score + 1 )
else
    print_FAIL; echo "manhattan 项目不存在"
fi

# 检查项目 gemini 是否存在
if oc get project gemini &>/dev/null; then
    score=$(expr $score + 1 )
    q2score=$(expr $q2score + 1 )
else
    print_FAIL; echo "gemini 项目不存在"
fi

# 检查项目 bluebook 是否存在
if oc get project bluebook &>/dev/null; then
    score=$(expr $score + 1 )
    q2score=$(expr $q2score + 1 )
else
    print_FAIL; echo "bluebook 项目不存在"
fi

# 检查项目 titan 是否存在
if oc get project titan &>/dev/null; then
    score=$(expr $score + 1 )
    q2score=$(expr $q2score + 1 )
else
    print_FAIL; echo "titan 项目不存在"
fi


# 检查用户 armstrong 是否是项目 apollo 的管理员
if oc get rolebinding -n apollo -o json | jq -e '.items[] | select(.subjects[]?.name == "armstrong" and .roleRef.name == "admin")' &>/dev/null; then
    score=$(expr $score + 1 )
    q2score=$(expr $q2score + 1 )
else
    print_FAIL; echo "armstrong 不是 apollo 项目的管理员"
fi

# 检查用户 armstrong 是否是项目 gemini 的管理员
if oc get rolebinding -n gemini -o json | jq -e '.items[] | select(.subjects[]?.name == "armstrong" and .roleRef.name == "admin")' &>/dev/null; then
    score=$(expr $score + 1 )
    q2score=$(expr $q2score + 1 )
else
    print_FAIL; echo "armstrong 不是 gemini 项目的管理员"
fi

# 检查用户 wozniak 是否可以查看项目 titan
if oc auth can-i get pods -n titan --as=wozniak &>/dev/null; then
    score=$(expr $score + 1 )
    q2score=$(expr $q2score + 1 )
else
    print_FAIL; echo "wozniak 不能查看 titan 项目"
fi

# 检查用户 wozniak 是否不能管理或删除项目 titan
if ! oc auth can-i delete project -n titan --as=wozniak &>/dev/null; then
    score=$(expr $score + 1 )
    q2score=$(expr $q2score + 1 )
else
    print_FAIL; echo "wozniak 可以管理或删除 titan 项目"
fi

if [ $q2score -eq 9 ]; then
    print_PASS; echo "Q2 添加角色到用户已配置"
fi

}

function q3_check_user_groups {

q3score=0

# 检查用户 armstrong 是否是 commander 组的成员
if oc get group commander -o json | jq -e '.users[] | select(. == "armstrong")' &>/dev/null; then
    score=$(expr $score + 1 )
    q3score=$(expr $q3score + 1 )
else
    print_FAIL; echo "armstrong 不是 commander 组的成员"
fi

# 检查用户 collins 是否是 pilot 组的成员
if oc get group pilot -o json | jq -e '.users[] | select(. == "collins")' &>/dev/null; then
    score=$(expr $score + 1 )
    q3score=$(expr $q3score + 1 )
else
    print_FAIL; echo "collins 不是 pilot 组的成员"
fi

# 检查用户 aldrin 是否是 pilot 组的成员
if oc get group pilot -o json | jq -e '.users[] | select(. == "aldrin")' &>/dev/null; then
    score=$(expr $score + 1 )
    q3score=$(expr $q3score + 1 )
else
    print_FAIL; echo "aldrin 不是 pilot 组的成员"
fi

# 检查 commander 组是否有 apollo 项目的 edit 权限
if oc get rolebinding -n apollo -o json | jq -e '.items[] | select(.subjects[]?.name == "commander" and .roleRef.name == "edit")' &>/dev/null; then
    score=$(expr $score + 1 )
    q3score=$(expr $q3score + 1 )
else
    print_FAIL; echo "commander 组没有 apollo 项目的 edit 权限"
fi

# 检查 pilot 组是否有 apollo 项目的 view 权限
if oc get rolebinding -n apollo -o json | jq -e '.items[] | select(.subjects[]?.name == "pilot" and .roleRef.name == "view")' &>/dev/null; then
    score=$(expr $score + 1 )
    q3score=$(expr $q3score + 1 )
else
    print_FAIL; echo "pilot 组没有 apollo 项目的 view 权限"
fi

if [ $q3score -eq 5 ]; then
    print_PASS; echo "Q3 用户和组配置已正确"
fi

}

function q4_check_quota {

q4score=0

# 检查是否存在名为 ex280-quota 的资源配额
if oc get quota ex280-quota -n manhattan &>/dev/null; then
    score=$(expr $score + 1)
    q4score=$(expr $q4score + 1)
else
    print_FAIL; echo "ex280-quota 不存在"
fi

# 检查 CPU 限制
if oc get quota ex280-quota -n manhattan -o json | jq -e '.status.hard.cpu == "2"' &>/dev/null; then
    score=$(expr $score + 1)
    q4score=$(expr $q4score + 1)
else
    print_FAIL; echo "CPU 限制不正确"
fi

# 检查内存限制
if oc get quota ex280-quota -n manhattan -o json | jq -e '.status.hard.memory == "1Gi"' &>/dev/null; then
    score=$(expr $score + 1)
    q4score=$(expr $q4score + 1)
else
    print_FAIL; echo "内存限制不正确"
fi

# 检查 Pod 限制
if oc get quota ex280-quota -n manhattan -o json | jq -e '.status.hard.pods == "3"' &>/dev/null; then
    score=$(expr $score + 1)
    q4score=$(expr $q4score + 1)
else
    print_FAIL; echo "Pod 限制不正确"
fi

# 检查服务限制
if oc get quota ex280-quota -n manhattan -o json | jq -e '.status.hard.services == "6"' &>/dev/null; then
    score=$(expr $score + 1)
    q4score=$(expr $q4score + 1)
else
    print_FAIL; echo "Service限制不正确"
fi

# 检查复制控制器限制
if oc get quota ex280-quota -n manhattan -o json | jq -e '.status.hard.replicationcontrollers == "3"' &>/dev/null; then
    score=$(expr $score + 1)
    q4score=$(expr $q4score + 1)
else
    print_FAIL; echo "复制控制器限制不正确"
fi

if [ $q4score -eq 6 ]; then
    print_PASS; echo "Q4 配额已正确配置"
fi

}


function q5_check_limit_range {

q5score=0

# 检查是否存在名为 ex280-limits 的 LimitRange
if oc get limitrange ex280-limits -n bluebook &>/dev/null; then
    score=$(expr $score + 1)
    q5score=$(expr $q5score + 1)
else
    print_FAIL; echo "ex280-limits 不存在"
fi

# 检查 Pod 内存限制
if oc get limitrange ex280-limits -n bluebook -o json | jq -e '.spec.limits[] | select(.type == "Pod") | .min.memory == "5Mi" and .max.memory == "300Mi"' &>/dev/null; then
    score=$(expr $score + 1)
    q5score=$(expr $q5score + 1)
else
    print_FAIL; echo "Pod 内存限制不正确"
fi

# 检查 Pod CPU 限制
if oc get limitrange ex280-limits -n bluebook -o json | jq -e '.spec.limits[] | select(.type == "Pod") | .min.cpu == "10m" and .max.cpu == "500m"' &>/dev/null; then
    score=$(expr $score + 1)
    q5score=$(expr $q5score + 1)
else
    print_FAIL; echo "Pod CPU 限制不正确"
fi

# 检查 Container 内存限制和默认请求
if oc get limitrange ex280-limits -n bluebook -o json | jq -e '.spec.limits[] | select(.type == "Container") | .min.memory == "5Mi" and .max.memory == "300Mi" and .defaultRequest.memory == "100Mi"' &>/dev/null; then
    score=$(expr $score + 1)
    q5score=$(expr $q5score + 1)
else
    print_FAIL; echo "Container 内存限制和默认请求不正确"
fi

# 检查 Container CPU 限制和默认请求
if oc get limitrange ex280-limits -n bluebook -o json | jq -e '.spec.limits[] | select(.type == "Container") | .min.cpu == "10m" and .max.cpu == "500m" and .defaultRequest.cpu == "100m"' &>/dev/null; then
    score=$(expr $score + 1)
    q5score=$(expr $q5score + 1)
else
    print_FAIL; echo "Container CPU 限制和默认请求不正确"
fi

if [ $q5score -eq 5 ]; then
    print_PASS; echo "Q5 LimitRange 已正确配置"
fi

}


function q6_check_scale {

q6score=0

# 检查是否存在名为 minion 的 DeploymentConfig
if oc get dc minion -n gru &>/dev/null; then
    score=$(expr $score + 1)
    q6score=$(expr $q6score + 1)
else
    print_FAIL; echo "minion DeploymentConfig 不存在"
fi

# 检查 minion 的副本数是否为 5
if oc get dc minion -n gru -o json | jq -e '.status.replicas == 5' &>/dev/null; then
    score=$(expr $score + 1)
    q6score=$(expr $q6score + 1)
else
    print_FAIL; echo "minion 的副本数不为 5"
fi

if [ $q6score -eq 2 ]; then
    print_PASS; echo "Q6 副本数已正确配置"
fi
}

function q7_check_autoscale {

q7score=0

# 检查是否存在名为 hydra 的 DeploymentConfig
if oc get dc hydra -n lerna &>/dev/null; then
    score=$(expr $score + 1)
    q7score=$(expr $q7score + 1)
else
    print_FAIL; echo "hydra DeploymentConfig 不存在"
fi

# 检查 hydra 的资源限制和请求
if oc get dc hydra -n lerna -o json | jq -e '.spec.template.spec.containers[] | .resources.limits.cpu == "100m" and .resources.requests.cpu == "25m"' &>/dev/null; then
    score=$(expr $score + 1)
    q7score=$(expr $q7score + 1)
else
    print_FAIL; echo "hydra 的资源限制和请求不正确"
fi

# 检查 hydra 的自动扩展策略
if oc get hpa hydra -n lerna -o json | jq -e '.spec.minReplicas == 6 and .spec.maxReplicas == 9 and .spec.metrics[0].resource.target.averageUtilization == 60' &>/dev/null; then
  score=$(expr $score + 1)
  q7score=$(expr $q7score + 1)
else
  echo "hydra 的自动扩展策略不正确"
fi

if [ $q7score -eq 3 ]; then
    print_PASS; echo "Q7 自动扩展策略已正确配置"
fi

}


function q8_check_route {

q8score=0

# 检查是否存在名为 oxcart 的 Route
if oc get route oxcart -n area51 &>/dev/null; then
    score=$(expr $score + 1)
    q8score=$(expr $q8score + 1)
else
    print_FAIL; echo "oxcart Route 不存在"
fi

# 检查 Route 的主机名是否正确
if oc get route oxcart -n area51 -o json | jq -e '.spec.host == "classified.apps.ocp4.example.com"' &>/dev/null; then
    score=$(expr $score + 1)
    q8score=$(expr $q8score + 1)
else
    print_FAIL; echo "Route 的主机名不正确"
fi

# 检查 Route 是否使用 edge termination
if oc get route oxcart -n area51 -o json | jq -e '.spec.tls.termination == "edge"' &>/dev/null; then
    score=$(expr $score + 1)
    q8score=$(expr $q8score + 1)
else
    print_FAIL; echo "Route 不使用 edge termination"
fi

# 检查 Route 是否使用正确的证书
if oc get route oxcart -n area51 -o json | jq -e '.spec.tls.certificate | contains("-----BEGIN CERTIFICATE-----")' &>/dev/null; then
    score=$(expr $score + 1)
    q8score=$(expr $q8score + 1)
else
    print_FAIL; echo "Route 没有使用证书"
fi

if [ $q8score -eq 4 ]; then
    print_PASS; echo "Q8 Route 已正确配置"
fi

}

function q9_check_deployment {

q9score=0

# 检查是否存在名为 ex280-repo 的 Helm 仓库
if helm repo list | grep -q 'ex280-repo'; then
    score=$(expr $score + 1)
    q9score=$(expr $q9score + 1)
else
    print_FAIL; echo "ex280-repo Helm 仓库不存在"
fi

# 检查是否存在名为 ascii-movie 的 Helm release
if helm list -n redhat-movie | grep -q 'ascii-movie'; then
    score=$(expr $score + 1)
    q9score=$(expr $q9score + 1)
else
    print_FAIL; echo "ascii-movie Helm release 不存在"
fi

# 检查是否存在名为 ascii-movie 的 Deployment
if oc get deployment -n redhat-movie | grep -q ascii-movie &>/dev/null; then
    score=$(expr $score + 1)
    q9score=$(expr $q9score + 1)
else
    print_FAIL; echo "ascii-movie Deployment 不存在"
fi

if [ $q9score -eq 3 ]; then
    print_PASS; echo "Q9 应用程序已正确部署"
fi

}

function q10_check_secret {

q10score=0

# 检查是否存在名为 magic 的 secret
if oc get secret magic -n math &>/dev/null; then
    score=$(expr $score + 1)
    q10score=$(expr $q10score + 1)
else
    print_FAIL; echo "magic secret 不存在"
fi

# 检查 secret 是否定义了名为 decoder_ring 的键和值
if oc get secret magic -n math -o json | jq -e '.data.decoder_ring == "NllXTjU3MnU1cTJqNTZHdUNnPT0="' &>/dev/null; then
    score=$(expr $score + 1)
    q10score=$(expr $q10score + 1)
else
    print_FAIL; echo "secret 没有定义正确的键和值"
fi

if [ $q10score -eq 2 ]; then
    print_PASS; echo "Q10 secret 已正确配置"
fi

}

function q11_check_application_secret {

q11score=0

# 检查是否存在名为 qed 的 DeploymentConfig
if oc get dc qed -n math &>/dev/null; then
    score=$(expr $score + 1)
    q11score=$(expr $q11score + 1)
else
    print_FAIL; echo "qed DeploymentConfig 不存在"
fi

# 检查 DeploymentConfig 是否使用了名为 magic 的 secret
if oc get dc qed -n math -o json | jq -e '.spec.template.spec.containers[].env[] | select(.name == "DECODER_RING" and .valueFrom.secretKeyRef.name == "magic")' &>/dev/null; then
    score=$(expr $score + 1)
    q11score=$(expr $q11score + 1)
else
    print_FAIL; echo "qed DeploymentConfig 没有使用名为 magic 的 secret"
fi

if [ $q11score -eq 2 ]; then
    print_PASS; echo "Q11 应用程序已正确配置使用 secret"
fi

}


function q12_check_service_account {

q12score=0

# 检查是否存在名为 ex280sa 的服务账户
if oc get sa ex280sa -n apples &>/dev/null; then
    score=$(expr $score + 1)
    q12score=$(expr $q12score + 1)
else
    print_FAIL; echo "Q12 ex280sa 服务账户不存在"
fi

# 检查服务账户是否具有 anyuid SCC
if oc get clusterrolebindings system:openshift:scc:anyuid -o yaml | grep -q ex280sa &>/dev/null; then
    score=$(expr $score + 1)
    q12score=$(expr $q12score + 1)
else
    print_FAIL; echo "Q12 ex280sa 服务账户没有 anyuid SCC"
fi

# 检查服务账户是否具有 cluster-admin 角色
if oc get clusterrolebinding -o json | jq -e '.items[] | select(.subjects[]?.name == "ex280sa" and .roleRef.name == "cluster-admin")' &>/dev/null; then
    score=$(expr $score + 1)
    q12score=$(expr $q12score + 1)
else
    print_FAIL; echo "Q12 ex280sa 服务账户没有 cluster-admin 角色"
fi

if [ $q12score -eq 3 ]; then
    print_PASS; echo "Q12 服务账户已正确配置"
fi

}

function q13_check_application_service_account {

q13score=0

# 检查是否存在名为 oranges 的 DeploymentConfig
if oc get dc oranges -n apples &>/dev/null; then
    score=$(expr $score + 1)
    q13score=$(expr $q13score + 1)
else
    print_FAIL; echo "oranges DeploymentConfig 不存在"
fi

# 检查 DeploymentConfig 是否使用了名为 ex280sa 的服务账户
if oc get dc oranges -n apples -o json | jq -e '.spec.template.spec.serviceAccountName == "ex280sa"' &>/dev/null; then
    score=$(expr $score + 1)
    q13score=$(expr $q13score + 1)
else
    print_FAIL; echo "oranges DeploymentConfig 没有使用名为 ex280sa 的服务账户"
fi

if [ $q13score -eq 2 ]; then
    print_PASS; echo "Q13 应用程序已正确配置使用服务账户"
fi

}

function q14_check_memory_request {

q14score=0

# 检查是否存在名为 atlas 的 Deployment
if oc get deployment atlas -n mercury &>/dev/null; then
    score=$(expr $score + 1)
    q14score=$(expr $q14score + 1)
else
    print_FAIL; echo "atlas Deployment 不存在"
fi

# 检查 Deployment 是否设置了内存请求为 128Mi
if oc get deployment atlas -n mercury -o json | jq -e '.spec.template.spec.containers[].resources.requests.memory == "128Mi"' &>/dev/null; then
    score=$(expr $score + 1)
    q14score=$(expr $q14score + 1)
else
    print_FAIL; echo "Q14 atlas Deployment 没有设置内存请求为 128Mi"
fi

if [ $q14score -eq 2 ]; then
    print_PASS; echo "Q14 内存请求已正确配置"
fi

}

function q15_check_application_data {

q15score=0

# 检查是否存在名为 phosphoric 的 Deployment
if oc get deployment phosphoric -n acid &>/dev/null; then
    score=$(expr $score + 1)
    q15score=$(expr $q15score + 1)
else
    print_FAIL; echo "phosphoric Deployment 不存在"
fi

# 检查 Deployment 是否使用了名为 sedicen 的配置映射
if oc get deployment phosphoric -n acid -o json | jq -e '.spec.template.spec.containers[].env[] | select(.name == "RESPONSE" and .valueFrom.configMapKeyRef.name == "sedicen")' &>/dev/null; then
    score=$(expr $score + 1)
    q15score=$(expr $q15score + 1)
else
    print_FAIL; echo "phosphoric Deployment 没有使用名为 sedicen 的配置映射"
fi

# 检查应用程序是否在指定的 URL 上运行
if curl -s http://phosphoric-acid.apps.ocp4.example.com | grep -q "Soda pop won't stop can't stop"; then
    score=$(expr $score + 1)
    q15score=$(expr $q15score + 1)
else
    print_FAIL; echo "应用程序没有在指定的 URL 上运行或显示不正确的文本"
fi

if [ $q15score -eq 3 ]; then
    print_PASS; echo "Q15 应用程序数据已正确配置"
fi

}

function q16_check_network_policy {

q16score=0

# 检查是否存在名为 db-allow-mysql-conn 的 NetworkPolicy
if oc get networkpolicy db-allow-mysql-conn -n database &>/dev/null; then
    score=$(expr $score + 1)
    q16score=$(expr $q16score + 1)
else
    print_FAIL; echo "db-allow-mysql-conn NetworkPolicy 不存在"
fi

# 检查 NetworkPolicy 是否配置了正确的 podSelector
if oc get networkpolicy db-allow-mysql-conn -n database -o json | jq -e '.spec.podSelector.matchLabels."network.openshift.io/policy-group" == "database"' &>/dev/null; then
    score=$(expr $score + 1)
    q16score=$(expr $q16score + 1)
else
    print_FAIL; echo "NetworkPolicy 没有配置正确的 podSelector"
fi

# 检查 NetworkPolicy 是否配置了正确的 namespaceSelector 和 podSelector
if oc get networkpolicy db-allow-mysql-conn -n database -o json | jq -e '.spec.ingress[].from[] | select(.namespaceSelector.matchLabels.team == "devsecops" and .podSelector.matchLabels.deployment == "web-mysql")' &>/dev/null; then
    score=$(expr $score + 1)
    q16score=$(expr $q16score + 1)
else
    print_FAIL; echo "NetworkPolicy 没有配置正确的 namespaceSelector 和 podSelector"
fi

# 检查 NetworkPolicy 是否配置了正确的端口
if oc get networkpolicy db-allow-mysql-conn -n database -o json | jq -e '.spec.ingress[].ports[] | select(.protocol == "TCP" and .port == 3306)' &>/dev/null; then
    score=$(expr $score + 1)
    q16score=$(expr $q16score + 1)
else
    print_FAIL; echo "NetworkPolicy 没有配置正确的端口"
fi

if [ $q16score -eq 4 ]; then
    print_PASS; echo "Q16 网络策略已正确配置"
fi

}

function q17_check_project_template {

q17score=0

# 检查是否存在名为 project-request 的 Template
if oc get template project-request -n openshift-config &>/dev/null; then
    score=$(expr $score + 1)
    q17score=$(expr $q17score + 1)
else
    print_FAIL; echo "project-request Template 不存在"
fi

# 检查 Template 是否配置了正确的 LimitRange
if oc get template project-request -n openshift-config -o json | jq -e '.objects[] | select(.kind == "LimitRange") | .metadata.name == "${PROJECT_NAME}-limits" and .spec.limits[].min.memory == "5Mi" and .spec.limits[].max.memory == "300Mi" and .spec.limits[].default.memory == "300Mi" and .spec.limits[].defaultRequest.memory == "100Mi"' &>/dev/null; then
    score=$(expr $score + 1)
    q17score=$(expr $q17score + 1)
else
    print_FAIL; echo "Template 没有配置正确的 LimitRange"
fi

if [ $q17score -eq 2 ]; then
    print_PASS; echo "Q17 项目模板已正确配置"
fi

}


function q18_check_operator {

q18score=0

# 检查是否存在名为 openshift-file-integrity 的项目
if oc get project openshift-file-integrity &>/dev/null; then
    score=$(expr $score + 1)
    q18score=$(expr $q18score + 1)
else
    print_FAIL; echo "openshift-file-integrity 项目不存在"
fi

# 检查是否安装了 file-integrity 操作器
if oc get csv -n openshift-file-integrity | grep -q 'file-integrity'; then
    score=$(expr $score + 1)
    q18score=$(expr $q18score + 1)
else
    print_FAIL; echo "file-integrity 操作器未安装"
fi

# 检查操作器的审批策略是否为 Automatic
if oc get subscription -n openshift-file-integrity -o json | jq -e '.items[] | select(.spec.name == "file-integrity-operator") | .spec.installPlanApproval == "Automatic"' &>/dev/null; then
    score=$(expr $score + 1)
    q18score=$(expr $q18score + 1)
else
    print_FAIL; echo "操作器的审批策略不是 Automatic"
fi

# 检查是否为 openshift-file-integrity 项目启用了集群监控
if oc get project openshift-file-integrity -o json | jq -e '.metadata.labels["openshift.io/cluster-monitoring"] == "true"' &>/dev/null; then
    score=$(expr $score + 1)
    q18score=$(expr $q18score + 1)
else
    print_FAIL; echo "未为 openshift-file-integrity 项目启用集群监控"
fi

if [ $q18score -eq 4 ]; then
    print_PASS; echo "Q18 操作器已正确安装和配置"
fi

}

function q19_check_cronjob {

q19score=0

# 检查是否存在名为 job-runner 的 CronJob
if oc get cronjob job-runner -n elementum &>/dev/null; then
    score=$(expr $score + 1)
    q19score=$(expr $q19score + 1)
else
    print_FAIL; echo "job-runner CronJob 不存在"
fi

# 检查 CronJob 是否配置了正确的调度时间
if oc get cronjob job-runner -n elementum -o json | jq -e '.spec.schedule == "5 4 2 * *"' &>/dev/null; then
    score=$(expr $score + 1)
    q19score=$(expr $q19score + 1)
else
    print_FAIL; echo "CronJob 没有配置正确的调度时间"
fi

# 检查 CronJob 是否配置了正确的成功作业历史记录限制
if oc get cronjob job-runner -n elementum -o json | jq -e '.spec.successfulJobsHistoryLimit == 14' &>/dev/null; then
    score=$(expr $score + 1)
    q19score=$(expr $q19score + 1)
else
    print_FAIL; echo "CronJob 没有配置正确的成功作业历史记录限制"
fi

# 检查 CronJob 是否使用了正确的服务账户
if oc get cronjob job-runner -n elementum -o json | jq -e '.spec.jobTemplate.spec.template.spec.serviceAccountName == "magna"' &>/dev/null; then
    score=$(expr $score + 1)
    q19score=$(expr $q19score + 1)
else
    print_FAIL; echo "CronJob 没有使用正确的服务账户"
fi

if [ $q19score -eq 4 ]; then
    print_PASS; echo "Q19 CronJob 已正确配置"
fi

}

function q20_check_support_information {

q20score=0

# 检查是否存在 must-gather 目录
if [ -d must-gather.local.* ]; then
    score=$(expr $score + 1)
    q20score=$(expr $q20score + 1)
else
    print_FAIL; echo "must-gather 目录不存在"
fi

# 检查是否存在压缩的 tar 存档文件
if [ -f ~student/must-gather-submit/ex280-ocp*tar.gz ]; then
    score=$(expr $score + 1)
    q20score=$(expr $q20score + 1)
else
    print_FAIL; echo "Q20 支持信息未正确收集和上传"
fi

}

function q21_check_pv_pvc_application {

q21score=0

# 检查是否存在名为 landing-pv 的 PersistentVolume
if oc get pv landing-pv &>/dev/null; then
    score=$(expr $score + 1)
    q21score=$(expr $q21score + 1)
else
    print_FAIL; echo "landing-pv PersistentVolume 不存在"
fi

# 检查是否存在名为 landing-pvc 的 PersistentVolumeClaim
if oc get pvc landing-pvc -n page &>/dev/null; then
    score=$(expr $score + 1)
    q21score=$(expr $q21score + 1)
else
    print_FAIL; echo "landing-pvc PersistentVolumeClaim 不存在"
fi

# 检查是否存在名为 landing 的 Deployment
if oc get deployment landing -n page &>/dev/null; then
    score=$(expr $score + 1)
    q21score=$(expr $q21score + 1)
else
    print_FAIL; echo "landing Deployment 不存在"
fi

# 检查 Deployment 是否使用了正确的 PersistentVolumeClaim
if oc get deployment landing -n page -o json | jq -e '.spec.template.spec.volumes[] | select(.persistentVolumeClaim.claimName == "landing-pvc")' &>/dev/null; then
    score=$(expr $score + 1)
    q21score=$(expr $q21score + 1)
else
    print_FAIL; echo "Deployment 没有使用正确的 PersistentVolumeClaim"
fi

# 检查应用程序是否在指定的 URL 上运行
if curl -s https://landing-page.apps.ocp4.example.com | grep -q "Congratulations"; then
    score=$(expr $score + 1)
    q21score=$(expr $q21score + 1)
else
    print_FAIL; echo "Q21 应用程序没有在指定的 URL 上运行"
fi

if [ $q21score -eq 5 ]; then
    print_PASS; echo "Q21 持久卷、持久卷声明和应用程序已正确配置"
fi

}

function q22_check_liveness_probe {

q22score=0

# 检查是否存在名为 atlas 的 Deployment
if oc get deployment atlas -n mercury &>/dev/null; then
    score=$(expr $score + 1)
    q22score=$(expr $q22score + 1)
else
    print_FAIL; echo "atlas Deployment 不存在"
fi

# 检查 Deployment 是否配置了正确的 liveness 探针
if oc get deployment atlas -n mercury -o json | jq -e '.spec.template.spec.containers[].livenessProbe | select(.tcpSocket.port == 8080 and .initialDelaySeconds == 10 and .timeoutSeconds == 30)' &>/dev/null; then
    score=$(expr $score + 1)
    q22score=$(expr $q22score + 1)
else
    print_FAIL; echo "Deployment 没有配置正确的 liveness 探针"
fi

if [ $q22score -eq 2 ]; then
    print_PASS; echo "Q22 liveness 探针已正确配置"
fi

}


# 调用函数
if [ $# -eq 0 ]; then
    pad
    pads
    padm
    print_PASS
    print_FAIL
    print_SUCCESS
    LINE
    wait_for_login
    q1_htpasswd
    q2_add_role_to_user
    q3_check_user_groups
    q4_check_quota
    q5_check_limit_range
    q6_check_scale
    q7_check_autoscale
    q8_check_route
    q9_check_deployment
    q10_check_secret
    q11_check_application_secret
    q12_check_service_account
    q13_check_application_service_account
    q14_check_memory_request
    q15_check_application_data
    q16_check_network_policy
    q17_check_project_template
    q18_check_operator
    q19_check_cronjob
    q20_check_support_information
    q21_check_pv_pvc_application
    q22_check_liveness_probe
else
    case $1 in
        1) q1_htpasswd ;;
        2) q2_add_role_to_user ;;
        3) q3_check_user_groups ;;
        4) q4_check_quota ;;
        5) q5_check_limit_range ;;
        6) q6_check_scale ;;
        7) q7_check_autoscale ;;
        8) q8_check_route ;;
        9) q9_check_deployment ;;
        10) q10_check_secret ;;
        11) q11_check_application_secret ;;
        12) q12_check_service_account ;;
        13) q13_check_application_service_account ;;
        14) q14_check_memory_request ;;
        15) q15_check_application_data ;;
        16) q16_check_network_policy ;;
        17) q17_check_project_template ;;
        18) q18_check_operator ;;
        19) q19_check_cronjob ;;
        20) q20_check_support_information ;;
        21) q21_check_pv_pvc_application ;;
        22) q22_check_liveness_probe ;;
        *) echo "选项无效，你只能输入1-22的数字" ;;
    esac
fi


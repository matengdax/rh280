#!/bin/bash

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
  X_char $[ $(echo $MSG_O | wc -c) + 8 ]
  print_SUCCESS; echo -e " \e[0;1m$MSG_N\e[0m$(SPACE $[ $(echo $MSG_O | wc -c) - $(echo $MSG_N | wc -c) + 8 ])"
}

echo -e "    ==> Waiting for OpenShift cluster start..."

# Wait for API to come online
MSG_O="Waiting for API..."
MSG_N="API is up"
until [ $(curl -k -s https://api.ocp4.example.com:6443/version?timeout=10s | jq -r '.major'     | grep -v null | wc -l) -eq 1 ]; do sleep 10; done &
MESSAGE
echo "        Cluster version is $(oc get clusterversion version -o json | jq -r '.status.history[0].version')"

# Wait for router come online
MSG_O="Waiting for router..."
MSG_N="Router is up"
until [ not $(curl -k -s https://console-openshift-console.apps.ocp4.example.com >/dev/null) ]; do sleep 10; done &
MESSAGE

# Wait for authentication come online
MSG_O="Waiting for authentication..."
MSG_N="Authentication is ready"
while true; do
  code=$(curl -k -s https://oauth-openshift.apps.ocp4.example.com)
  if [[ ! -z ${code} ]] \
    && [[ "${code:0:1}" == "{" ]] \
    && [[ $(echo $code | jq -r '.code') -eq 403 ]]; then
    break
  fi
  sleep 10
done &
MESSAGE

# Set KUBECONFIG
[ ! -d /home/${USER}/.kube ] && mkdir /home/${USER}/.kube
oc login -u admin -p redhatocp https://api.ocp4.example.com:6443 &>/dev/null

# Wait for Pod ready
MSGG_O="Waiting for the POD to be ready..."
MSG_N="The POD is ready"
until oc get pod --no-headers -A | grep -v openshift-marketplace 2>/dev/null \
  | egrep -v 'Running|Completed' \
  | wc -l \
  | grep -wq 0; do sleep 1; done &
MESSAGE

echo -e " \e[32m[ OK ]\e[0m OpenShift cluster ready.\n"
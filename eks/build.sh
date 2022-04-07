#!/usr/bin/env bash

# Prerequisite
# Make sure you set secret enviroment variables in Travis CI
# DOCKER_USERNAME
# DOCKER_PASSWORD
# API_TOKEN

# set -ex

image="alpine/terragrunt"
repo="hashicorp/terraform"

if [[ ${CI} == 'true' ]]; then
  CURL="curl -sL -H \"Authorization: token ${API_TOKEN}\""
else
  CURL="curl -sL"
fi

latest=$(${CURL} https://api.github.com/repos/${repo}/releases/latest |jq -r .tag_name|sed 's/v//')
latest=0.14.11
eks="${latest}-eks"

#terragrunt=$(${CURL} https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest |jq -r .tag_name)
terragrunt=v0.28.24

sum=0
echo "Lastest terraform release is: ${latest}"

tags=`curl -s https://hub.docker.com/v2/repositories/${image}/tags/ |jq -r .results[].name`

for tag in ${tags}
do
  if [ ${tag} == ${eks} ];then
    sum=$((sum+1))
  fi
done

# get available Amazon EKS Kubernetes versions, only pick up the top version
# https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
KUBECTL=$(curl -s https://raw.githubusercontent.com/awsdocs/amazon-eks-user-guide/master/doc_source/kubernetes-versions.md |egrep -A 10 "The following Kubernetes versions"|grep ^+ |awk '{gsub("\\\\", ""); print $NF}' |sort -Vr|head -1)
KUBECTL=1.19.15
echo "Latest kubectl is $KUBECTL"

# get latest eksctl
EKSCTL=$(curl -s https://api.github.com/repos/weaveworks/eksctl/releases | jq -r '.[].tag_name' |grep -v "\-rc" | sed 's/v//' | sort -rV | head -n 1)
echo "Latest eksctl is $EKSCTL"

sed "s/VERSION/${latest}/" Dockerfile.template > Dockerfile
docker build --build-arg TERRAGRUNT=${terragrunt} --build-arg KUBECTL=${KUBECTL} --build-arg EKSCTL=${EKSCTL} --no-cache -t ${image}:${eks} .

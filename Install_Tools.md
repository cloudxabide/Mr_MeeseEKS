# Install Tools

## Install kubectl
```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
```
The following I modified from the original.  (if you do not understand what the next command does, feel free to follow the guide from kubernete.io (link below)  
```
$(echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check) && { sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl; } || { echo "ERROR: checksum did not match"; }

```
From: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

## Install/Update AWS CLI

(NOTE:  I will revisit this, but it *does* appear to be the best way to approach this)
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
aws --version
sudo ./aws/install
aws --version
```

Ouput: (2023-01-18)
```
codedemo:~/environment $ aws --version
aws-cli/1.19.112 Python/2.7.18 Linux/4.14.301-224.520.amzn2.x86_64 botocore/1.20.112
codedemo:~/environment $ sudo ./aws/install 
You can now run: /usr/local/bin/aws --version
codedemo:~/environment $ aws --version
aws-cli/2.9.15 Python/3.9.11 Linux/4.14.301-224.520.amzn2.x86_64 exe/x86_64.amzn.2 prompt/off
```

## Install GNU utilities

Install utilities and create alias to run yq (yq portion is optional)
```
sudo yum -y install jq gettext bash-completion moreutils
echo 'yq() {
  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq "$@"
}' | tee -a ~/.bashrc && source ~/.bashrc
```

Ensure tools were installed correctly
```
for command in kubectl jq envsubst aws
  do
    which $command &>/dev/null && echo "$command in path" || echo "$command NOT FOUND"
  done
```

### Enable Bash Completion for Kubectl
```
kubectl completion bash >>  ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion
```

## Random bits
Update the Load Balancer Controller version
```
echo 'export LBC_VERSION="v2.4.1"' >>  ~/.bash_profile
echo 'export LBC_CHART_VERSION="1.4.1"' >>  ~/.bash_profile
.  ~/.bash_profile
```

# Mr MeeseEKS

I connect with very few "pop culture" things these days.  Mostly because I am old... and busy... grumpy... (I digress).  But, I do enjoy some Rick and Morty.  More enjoyable that Mr Meeseeks literally has EKS in his name, and I thought it fitting that Mr Meeseeks exemplifies the "Can Do Spirit" and so... here we are

[I'm Mr. Meeseeks, look at me!](https://youtu.be/l4iZtDBYkZA?start=3&end=15)

[Ooooohh Yaaaaa!   Cannnn dooo!](https://youtu.be/mW-JmtGfW_A?t=31)  Nailed it.

[Amazon Elastic Kubernetes Service (EKS)](https://aws.amazon.com/eks/) handles a *SIGNIFICANT* amount of "undiferentiated heavy lifting" that is involved with Kubernetes.  

Amazon EKS advantages - a few that I find compelling:  
* Installation of Kubernetes
* Operation and Maintenance of the Kubernetes cluster
* Management of the Kubernetes control-plane

Additionally, you still can leverage the growing number of tools, approaches, etc.. that the Kubernetes community has to offer (like Karpenter, which we'll be checking out).

I am going to "try something" with this repo:  for the more involved and "auxilary" tasks, I will create a separate doc and link to it.  An example would be the procedure for creating Cloud9 Environment - that way, if you already know how to do that, you won't have to sort through lots of content that does not apply.

## Prerequisites and considerations

* Active AWS account with adequate permissions to perform the actions in this script (sorry for being vague here - I don't have a succinct list of privs for this activity at this time)

While I use [AWS Cloud9](https://aws.amazon.com/cloud9/) that is not a necessity.  (I do recommend you check it out though, if you've not used it).

## Configure Cloud9 Environment - Install tools and configure account
We will install (or update) kubectl, eksctl, awscli

[Create your Cloud9 Environment](Create_Cloud9_Environment.md)  
Login in to your [Cloud9 Environment](https://us-east-1.console.aws.amazon.com/cloud9control/)  
Run through the [Install Tools](Install_Tools.md) doc  
[Modify IAM settings for your Workspace](./Modify_IAM_Settings.md)

## Create your EKS Cluster
### Slight diversion... create a VPC
https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html

```
MY_CLUSTER="eksdemo"
MY_REGION="us-east-1"
MY_K8S_VERSION="1.31"
STACK_NAME="${MY_CLUSTER}"
FILE=amazon-eks-vpc-3-private-subnets.yaml # VPC with 3 pub, 3 priv
FILE=amazon-vpc-3-public-private-tgw-subnets.yaml # VPC with 3 pub, 3 priv, and 3 TGW subnets
```

NOTE:  I am directing you to pull a file from *my* Git Repo... So, I urge caution, and then advise you to compare to the AWS example. (coming from a guy who names his repo after Rick and Morty characters ;-)  

Changes I made:
* Added *-03 subnets (pub and priv)
* Modified the CIDR from a /18 to a /19 (16,384 to 8,192) for each subnet

### Standard VPC
```
curl -o amazon-eks-vpc-private-subnets.yaml https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml
curl -o $FILE https://raw.githubusercontent.com/cloudxabide/Mr_MeeseEKS/main/Files/${FILE}
sdiff amazon-eks-vpc-private-subnets.yaml ${FILE}
```

Tip:  If you want to swap CIDR
```
sed -i -e 's/10.1./172.17./g' ${FILE}
```

```
aws cloudformation create-stack --stack-name "${STACK_NAME}" \
  --template-body file://${FILE} \
  --region ${MY_REGION} 
```

```
aws cloudformation list-stacks --query 'StackSummaries[?starts_with(StackName, `eksdemo`)].{StackName:StackName,StackStatus:StackStatus} | sort_by(@, &StackName)'
```

### OK.. now on to the cluster
```
# Get the VPC_ID for the eksdemo VPC we created
MY_VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eksdemo-vpc" --query "Vpcs[].VpcId" --output=text)

# Gather the SubnetId for the private subnets
SUBNETS=$(aws ec2 describe-subnets --region $MY_REGION  --filters "Name=vpc-id,Values=${MY_VPC_ID}" --query 'Subnets[?MapPublicIpOnLaunch==`false`].SubnetId' --output=text)
# aws ec2 describe-subnets --region $MY_REGION  --filters "Name=vpc-id,Values=${MY_VPC_ID}" "Name=map-public-ip-on-launch,Values=false" --query 'Subnets[?MapPublicIpOnLaunch==`false`].SubnetId' --output=text
SUBNETS=$(aws ec2 describe-subnets --region $MY_REGION  --filters "Name=vpc-id,Values=${MY_VPC_ID}" "Name=map-public-ip-on-launch,Values=false" "Name=tag:Name,Values=*eksdemo-PrivateSubnet*" --query 'Subnets[?MapPublicIpOnLaunch==`false`].SubnetId' --output=text)
```

The following command is not async - i.e. it will keep providing output until it is complete.  Enjoy!
```
echo "SUBNETS: $SUBNETS"
echo "MY_REGION: $MY_REGION"
echo "MY_K8S_VERSION: $MY_K8S_VERSION"
eksctl create cluster --name ${MY_CLUSTER} --region ${MY_REGION} --version ${MY_K8S_VERSION} --vpc-private-subnets $(echo $SUBNETS | sed 's/ /,/g') --without-nodegroup
```

## Query for Stack tht creates cluster
```
aws cloudformation list-stacks --query 'StackSummaries[?starts_with(StackName, `eksctl-eksdemo`)].{StackName:StackName,StackStatus:StackStatus} | sort_by(@, &StackName)'
```
## Update Logging
```bash
eksctl utils update-cluster-logging --enable-types=all --region=$MY_REGION --cluster=$MY_CLUSTER --approve
#    eksctl utils update-cluster-logging --enable-types api,audit --disable-types controllerManager,scheduler --cluster=<cluster-name>
```

## Create a Managed Node Group
[Create a Managed Node Group](./Create_Managed_NodeGroup.md)

## Create a Managed Node Group with SPOT (Future)

## Enable Metrics
[Enable Metrics](./Enable_Metrics.md)

## Deploy a Simple App
This app is really cool.  It provides a "visual representation" of where the 3-tiers of pods are running.

[Deploy Demo App - 3-tier](Deploy_Demo_App.md)

## Deploy Java App using Code Pipeline
This one is a bit more complicated/involved.  It will deploy all the resources necessary to deploy a simple Java WebApp using AWS Code Developer Tools

## References
[Getting started with Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)  


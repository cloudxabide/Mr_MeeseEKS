# Create a Managed NodeGroup 


```
MY_REGION=us-east-1
MY_CLUSTER=poceks
aws ec2 create-key-pair --region $MY_REGION --key-name poceks --query 'KeyMaterial' --output text > MrMeeSeEKS.pem
 aws ec2 describe-key-pairs --key-name poceks

```

```
eksctl create nodegroup \
  --cluster poceks \
  --region $MY_REGION \
  --name my-mng-al2 \
  --node-ami-family AmazonLinux2 \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 4 \
  --ssh-access \
  --ssh-public-key poceks \
  --asg-access \
  --external-dns-access \
  --full-ecr-access \
  --managed \
  --node-private-networking

```

```
eksctl create nodegroup \
  --cluster poceks \
  --region $MY_REGION \
  --name my-mng-bottlerocket \
  --node-ami-family Bottlerocket \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 4 \
  --ssh-access \
  --ssh-public-key poceks \
  --asg-access \
  --external-dns-access \
  --full-ecr-access \
  --managed \
  --node-private-networking
```

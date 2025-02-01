# Deploy Demo App (manual)

(I'll add commenting later)

aws eks update-kubeconfig --name eksdemo

```
kubectl create namespace ecsdemo
kubectl config set-context --current --namespace=ecsdemo
aws kms create-alias --alias-name alias/eksworkshop --target-key-id $(aws kms create-key --query KeyMetadata.Arn --output text)
export MASTER_ARN=$(aws kms describe-key --key-id alias/eksworkshop --query KeyMetadata.Arn --output text)
echo "export MASTER_ARN=${MASTER_ARN}" | tee -a ~/.bash_profile

c9builder=$(aws cloud9 describe-environment-memberships --environment-id=$C9_PID | jq -r '.memberships[].userArn')
if echo ${c9builder} | grep -q user; then rolearn=${c9builder};         echo Role ARN: ${rolearn}; elif echo ${c9builder} | grep -q assumed-role; then         assumedrolename=$(echo ${c9builder} | awk -F/ '{print $(NF-1)}');         rolearn=$(aws iam get-role --role-name ${assumedrolename} --query Role.Arn --output text) ;         echo Role ARN: ${rolearn}; fi
eksctl create iamidentitymapping --cluster eksworkshop-eksctl --arn ${rolearn} --group system:masters --username admin

kubectl describe configmap -n kube-system aws-auth

git clone https://github.com/aws-containers/ecsdemo-frontend.git
git clone https://github.com/aws-containers/ecsdemo-nodejs.git
git clone https://github.com/aws-containers/ecsdemo-crystal.git

## As I am not a fan of deploying stuff in to the "default" namespace
find . -depth 3 -name deployment.yaml -exec sed -i -e 's/default/ecsdemo/g' {} \;

cd ecsdemo-nodejs
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl get deployment ecsdemo-nodejs
cd -

cd ecsdemo-crystal
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl get deployment ecsdemo-crystal
aws iam get-role --role-name "AWSServiceRoleForElasticLoadBalancing" || aws iam create-service-linked-role --aws-service-name "elasticloadbalancing.amazonaws.com"
cd -

cd ecsdemo-frontend
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl get deployment ecsdemo-frontend
cd -

curl -o replica_control.sh https://raw.githubusercontent.com/cloudxabide/Mr_MeeseEKS/main/Scripts/replica_control.sh
chmod +x replica_control.sh
./replica_control.sh up
URL=$(kubectl get service/ecsdemo-frontend -n ecsdemo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
kubectl config set-context --current --namespace=default
```

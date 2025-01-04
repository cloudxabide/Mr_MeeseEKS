# Build the Builder Build
Status:  This just "notes" at this point (Jan 2023)
          I will improve the formatting so this is easier to follow

I am using the following naming "standard"  
${APPNAME}-${MYDATE}-${MYVERSION}  
ex. codedemo-20230106-01  

CodeCommit Repo:  
CodePipeline:  
S3 Bucket:  

## Variables for this Demo
```
APPNAME="codedemo"  
ENVIRONMENT="test"
MYDATE=$(date +%F)
PROJECT="${APPNAME}-${MYDATE}"
REGION="us-west-2"

echo "Using Project: ${PROJECT}"
echo "Deployed in Region: $REGION"
```

```
mkdir -p ${HOME}/Projects/${PROJECT}/; cd $_
wget https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/samples/p-attach/95a5b5c2-d7fb-41eb-9089-455318c0d585/attachments/attachment.zip
unzip attachment.zip 
unzip java-cicd-eks-cfn.zip   

aws s3 mb s3://${PROJECT}
# NOTE: we need to create a folder ("Code") which will happen when we cp bits up to the bucket
# ALSO NOTE: it is *here* you would make code changes (see bottom of this doc)
aws s3 cp $(find . -name app_code.zip) s3://${PROJECT}/Code/   
aws s3 ls s3://${PROJECT}/Code/
```

## Create the Stack which will create 
  * ECR repo
 * CodeCommit repo
```
STACK_NAME="${PROJECT}-codecommit-ecr"
STACK_PARAMETERS=${STACK_NAME}.cfn
STACK_PARAMETERS_TMP=${STACK_NAME}.cfn.tmp
#######
# Create Human-Readable "params", then parse it in to json 
cat << EOF > ${STACK_PARAMETERS_TMP}
CodeCommitRepositoryName              $APPNAME	
ECRRepositoryName	              ${PROJECT}
CodeCommitRepositoryS3BucketObjKey    Code/app_code.zip
CodeCommitRepositoryBranchName	      master	
CodeCommitRepositoryS3Bucket	      ${PROJECT}
EOF

grep -v ^# $STACK_PARAMETERS_TMP | while read ParameterKey ParameterValue DUMMY; do echo -e "  {\n    \"ParameterKey\": \"${ParameterKey}\",\n    \"ParameterValue\": \"${ParameterValue}\"\n  },"; done > ${STACK_PARAMETERS}
#- once you have the params.json created, add open/close square-brackets at the beginning and end
case `sed --version | head -1` in
  *GNU*)
    # Remove the entries which are just a hypen "-"
    sed -i -e 's/"-"/""/g' ${STACK_PARAMETERS}
    # Add the '[' to the beginning of the file
    sed -i -e '1i[' ${STACK_PARAMETERS}
    # Remove the trailing ',' from the last entry
    sed  -i '$ s/},/}/' ${STACK_PARAMETERS}
  ;;
  *)
sed -i'' '1i\
[\
' ${STACK_PARAMETERS}
  ;;
esac
echo "]" >> ${STACK_PARAMETERS}
```

## Validate the provided template 
```
aws cloudformation validate-template --template-body file://$(find . -name codecommit.yaml)                       
aws cloudformation create-stack --stack-name "${STACK_NAME}" \
  --template-body file://$(find . -name codecommit.yaml) \
  --parameters file://${STACK_PARAMETERS} \
  --region $REGION

# --query 'StackSummaries[?starts_with(StackName, `codedemo`)].{StackName:StackName,StackStatus:StackStatus} | sort_by(@, &StackName)'
aws ecr describe-repositories --query
#  Need to figure out how to pass a var in to the following command/query - $APPNAME, for example
ECR_URL=$(aws ecr describe-repositories  --query 'repositories[?contains(repositoryUri,`codedemo`)].{repositoryUri:repositoryUri}' --output text --no-cli-pager )
ECR_URL_BASE=$(echo $ECR_URL  | grep codedemo | cut -f1 -d\/  )

aws codecommit list-repositories --query "repositories[].repositoryName" --output text
```

## Update aws-proserve-java-greeting code
```
sed -i -e "s/509501787486.dkr.ecr.us-east-2.amazonaws.com/$ECR_URL_BASE/g" $(find . -name values.dev.yaml)
```


CFN Template to deploy CodePipeline to build Docker Image of java application 
  and push to ECR and deploy to EKS
```
STACK_NAME="${PROJECT}-codepipeline"
STACK_PARAMETERS=${STACK_NAME}.cfn
STACK_PARAMETERS_TMP=${STACK_NAME}.cfn.tmp

# Need to get this to query for the cluster name 
#EKS_CLUSTER_NAME=$(aws eks list-clusters --query "clusters" --output text)
EKS_CLUSTER_NAME=codedemo
cat << EOF > ${STACK_PARAMETERS_TMP}
EKSCodeBuildAppName	aws-proserve-java-greeting
EcrDockerRepository	${PROJECT}
SourceRepoName ${APPNAME}
CodeBranchName	master
EKSClusterName	$EKS_CLUSTER_NAME
EnvType dev 
EOF

grep -v ^# $STACK_PARAMETERS_TMP | while read ParameterKey ParameterValue DUMMY; do echo -e "  {\n    \"ParameterKey\": \"${ParameterKey}\",\n    \"ParameterValue\": \"${ParameterValue}\"\n  },"; done > ${STACK_PARAMETERS}
#- once you have the params.json created, add open/close square-brackets at the beginning and end
case `sed --version | head -1` in
  *GNU*)
    # Remove the entries which are just a hypen "-"
    sed -i -e 's/"-"/""/g' ${STACK_PARAMETERS}
    # Add the '[' to the beginning of the file
    sed -i -e '1i[' ${STACK_PARAMETERS}
    # Remove the trailing ',' from the last entry
    sed  -i '$ s/},/}/' ${STACK_PARAMETERS}
  ;;
  *)
sed -i'' '1i\
[\
' ${STACK_PARAMETERS}
  ;;
esac
echo "]" >> ${STACK_PARAMETERS}

# Validate the provided template
aws cloudformation validate-template --template-body file://$(find . -name build_deployment.yaml)
aws cloudformation create-stack --stack-name "${STACK_NAME}" \
  --template-body file://$(find . -name build_deployment.yaml) \
  --parameters file://${STACK_PARAMETERS} \
  --capabilities CAPABILITY_NAMED_IAM \ 
  --region $REGION

aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region ${REGION}
aws cloudformation --region=${REGION} describe-stacks --query "Stacks[?StackName=='${PROJECT}-codepipeline'].Outputs[0].OutputValue" --output text
```

```
bash $(find . -name kube_aws_auth_configmap_patch.sh) $(aws cloudformation --region=${REGION} describe-stacks --query "Stacks[?StackName=='${PROJECT}-codepipeline'].Outputs[0].OutputValue" --output text)
```

## You now need to update a few things (updates in CodeCommit will trigger a new build)
In CodeCommit Console, check out CodeCommit | Repositories | Code
codedemo/buildspec.yml
change/update
      - trivy --no-progress --exit-code 1 --severity HIGH,CRITICAL --auto-refresh $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$CODEBUILD_RESOLVED_SOURCE_VERSION
to 
      - trivy image $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$CODEBUILD_RESOLVED_SOURCE_VERSION

Then... approve (in CodePipeline)

## Check out the end of the CodeBuild and revie teh logs.  At teh very end is the endpoint you can acces (or review EC2: LoadBalancers)


Also (I have no clue how the versioning works, or why it matters)
codedemo/app/pom.xml
project: parent: version: 2.0.5.RELEASE
to
project: parent: version: 2.0.9.RELEASE
or...
project: parent: version: 2.7.7.RELEASE


Push AmazonCorretto image to your repo (This is still a WIP)
``` 
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL_BASE

# registry/repository:tag
IMAGE=amazoncorretto:8-alpine
IMAGE_TAG=$(echo $IMAGE | cut -f2 -d\:)
docker pull $IMAGE

docker tag $IMAGE $ECR_URL:$IMAGE_TAG
docker push $ECR_URL/$IMAGE_TAG
``` 

# The following... works (just an example)
``` 
docker tag amazoncorretto:8-alpine $ECR_URL:latest
docker push $ECR_URL:latest
``` 


### RANDOM BITS
``` 
aws eks list-clusters --query "clusters[]" --output text --no-cli-pager
aws codecommit list-repositories --query "repositories[].repositoryName" --output=text
``` 

aws cloudformation --region=us-east-1 describe-stacks --query "Stacks[?StackName=='codedemo-20231015-pipeline'].Outputs[0].OutputValue" --output text


## Customize your code
### So, there is an version1/app_code dir that contains an app_code.zip
You would want to 
* make a backup of app (mv app app.bak
unzip app_code.zip
vi app/src/main/java/org/aws/samples/greeting/GreetingController.jav
update the line with "return"
zip app_code.zip app
THEN.... copy it to s3

The trigger is implemented via: "PollForSourceChanges - App"

# Create Cloud9 Environment

## Create the Cloud9 Environment (instance)
Browse to [AWS Cloud9](https://us-east-1.console.aws.amazon.com/cloud9control/home?region=us-east-1#/product) product page.  
Click on Create Environment

Details
- Name: mrmeeseeks
- Description - optional: Cloud9 IDE for EKS Learning
- Environment type: New EC2 instance (default)

New EC2 instance
- Instance Type: t3.small (I bump this from free tier in case I choose to implement a number of things)
- Platform: Amazon Linux 2 (default)

I leave the remainder at the defaults.  Review the warning at the bottom and click "Create"

## Increase the disk size
Once the Environment is up, click Open.  When you see the IDE, click Window | New Terminal  
![Window | New Terminal](./images/New_Terminal.png)

You should run the following code at the command line (which will reboot the instance)

```
pip3 install --user --upgrade boto3
export instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
python -c "import boto3
import os
from botocore.exceptions import ClientError 
ec2 = boto3.client('ec2')
volume_info = ec2.describe_volumes(
    Filters=[
        {
            'Name': 'attachment.instance-id',
            'Values': [
                os.getenv('instance_id')
            ]
        }
    ]
)
volume_id = volume_info['Volumes'][0]['VolumeId']
try:
    resize = ec2.modify_volume(    
            VolumeId=volume_id,    
            Size=30
    )
    print(resize)
except ClientError as e:
    if e.response['Error']['Code'] == 'InvalidParameterValue':
        print('ERROR MESSAGE: {}'.format(e))"
if [ $? -eq 0 ]; then
    sudo reboot
fi
```


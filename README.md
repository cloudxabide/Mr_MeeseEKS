# README

I connect with very few "pop culture" things these days.  Mostly because I am old... and busy... grumpy... (I digress).  But, I do enjoy some Rick and Morty.  More enjoyable that Mr Meeseeks literally has EKS in his name.  So... here we are.

[I'm Mr. Meeseeks, look at me!](https://youtu.be/l4iZtDBYkZA?start=3&end=15)

[Ooooohh Yaaaaa!   Cannnn dooo!](https://youtu.be/mW-JmtGfW_A?t=31)  Nailed it.

[Amazon Elastic Kubernetes Service (EKS)](https://aws.amazon.com/eks/) handles a *SIGNIFICANT* amount of "undiferentiated heavy lifting" that is involved with Kubernetes.  

Examples of Amazon EKS advantages:  
* Installation of Kubernetes
* Operation and Maintenance of the Kubernetes cluster
* Management of the Kubernetes control-plane

Additionally, you still can leverage the growing number of tools, approaches, etc.. that the Kubernetes community has to offer (like Karpenter, which we'll be checking out).

I am going to "try something" with this repo:  for the more involved and "auxilary" tasks, I will create a separate doc and link to it.  An example would be the procedure for creating Cloud9 Environment - that way, if you already know how to do that, you won't have to sort through lots of content that does not apply.

## Prerequisites and considerations

* Active AWS account with adequate permissions to perform the actions in this script (sorry for being vague here - I don't have a succinct list of privs for this activity at this time)

While I use [AWS Cloud9](https://aws.amazon.com/cloud9/) that is not a necessity.  (I do recommend you check it out though, if you've not used it).


## Install tools and configure account
We will install (or update) kubectl, eksctl, awscli

[Create your Cloud9 Environment](Create_Cloud9_Environment.md)  
Login in to your [Cloud9 Environment](https://us-east-1.console.aws.amazon.com/cloud9control/) 

## References
[Getting started with Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)  


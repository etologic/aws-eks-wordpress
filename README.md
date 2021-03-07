# ADM Wordpress Solution

## Wordpress Solution design

![Alt text](images/infra_solution_diagram.png?raw=true "solution_diagram")

This solution will cover the following main targets.
* Security 
* Scalability 
* High availability.  

### Security

There are three private subnets to maintain EKS cluster and RDS Multi AZ setup. EKS clusters and RDS can be accessed through only ec2 or services in public subnet. 

 There is a bastion host to maintain access to environment. A bastion host is a server whose purpose is to provide access to a private network from an external network, such as the Internet. Because of its exposure to potential attack, a bastion host must minimize the chances of penetration.

There are multiple security groups to control access to each component. All security groups are listed in security-group.tf.
Every Security Group works in a similar fashion to a firewall as it carries a set of rules that filter traffic entering and leaving the EC2 instances. As said earlier, security groups are associated with the EC2 instances,RDS and offer protection at the ports and protocol access level.

### Scalability

There are three auto scaling groups in this environment which will help scale instances in each availability zone. All these eks worker autoscaling groups are attached to one elb which contoles tafric to wordpress web application. 

In this environment I used dynamic scaling to increase desired nodes in the auto scaling group. I are using target tracking scaling policy to keep the average aggregate CPU utilization of your Auto Scaling group at 50 percent. 

I used Horizontal Pod Autoscaler to increase the number of pods based on cpu utilization of pods.Horizontal Pod Autoscaler automatically scales the number of Pods in a  deployment based on observed CPU utilization.

I used persistent storage in Amazon EKS which will help scale pods and all the file systems will be syncyed. I used Amazon EFS CSI driver to create persistent storage.

I didn't have time to cover session management during this project.


### High availability(HA)

High Availability describes systems that are dependable enough to operate continuously without failing

I used three avilability zones to maintain HA in this setup. RDS is setup as Multi AZ deployment which will keep standby RDS if something happends to master RDS. 


## Infrustucture provisiioning 

* Install AWS CLI
* Setup IAM account to provision environment 
* Create AWS key pair
* Install terraform v0.13.5
* Configure AWS CLI
* Create AWS key pair
* Setup terraform code repo in local machine
* Terraform initialization
* Terraform apply
* Setup wordpress site
* Login to bastion server 
* Install kubectl
* Configure kubectl
* Login to database



### 1. Setup IAM account to provision environment 

* Use your AWS account ID or account alias, your IAM user name, and your password to sign in to the IAM console.

* In the navigation bar on the upper right, choose your user name, and then choose My Security Credentials.

![Alt text](images/sc.png?raw=true "solution_diagram")

* Expand the Access keys (access key ID and secret access key) section.

* To create an access key, choose Create New Access Key. If this feature is disabled, then you must delete one of the existing keys before you can create a new one. A warning explains that you have only this one opportunity to view or download the secret access key. To copy the key to paste it somewhere else for safekeeping, choose Show Access Key. To save the access key ID and secret access key to a .csv file to a secure location on your computer, choose Download Key File.

### 2. Install AWS CLI

Please use following URL to install AWS CLI
* https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-prereq


### 3. Create AWS key pair

Login to AWS console and navigate to ec2 section. EC2 section click on Key Pairs sub section under NETWORK & SECURITY category. 
 Press Create Key Pair button and create new key pair named as following
 ```shell
 "aws_eks_cluster_master_key"
```

![Alt text](images/key_pair.png?raw=true "Key Pair")

### 4. Setup terraform code repo in local machine
 
 Open terminal and enter following command
 
 ```shell
git clone git@github.com:Anushkasandaruwan/aws-eks-wordpress.git && cd aws-eks-wordpress
```

### 5. Install terrafrom = >v0.13.5

Please use following URL to install terrafrom in your local computer

https://learn.hashicorp.com/tutorials/terraform/install-cli

### 6. Configure AWS CLI

After installing the AWS CLI. Configure it to use your credentials.
 

```shell
$ aws configure
AWS Access Key ID [None]: <YOUR_AWS_ACCESS_KEY_ID>
AWS Secret Access Key [None]: <YOUR_AWS_SECRET_ACCESS_KEY>
Default region name [None]: us-east-1
Default output format [None]: text
```

This enables Terraform access to the configuration file and performs operations on your behalf with these security credentials.

### 7. Terraform initialization

After you've done configure AWS CLI, initialize your Terraform workspace, which will download 
the provider and initialize it with the values provided in the `vars.tf` file.

```shell
$ terraform init
Initializing modules...

Initializing the backend...

Initializing provider plugins...
- Using previously-installed hashicorp/null v2.1.2
- Using previously-installed hashicorp/random v2.3.1
- Using previously-installed hashicorp/template v2.2.0
- Using previously-installed gavinbunney/kubectl v1.9.1
- Using previously-installed hashicorp/aws v3.15.0
- Using previously-installed hashicorp/kubernetes v1.13.3
- Using previously-installed hashicorp/local v1.4.0


Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

```

### 9. Terraform apply

Then, provision your EKS cluster by running `terraform apply`. This will 
take approximately 10 minutes.

```shell
$ terraform apply

# Output truncated...

Plan: 80 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

# Output truncated...

Apply complete! Resources: 80 added, 0 changed, 0 destroyed.

Outputs:

Outputs:

bastion_public_IP = [
  "18.191.46.157",
]
cluster_endpoint = https://33DD99BE6C094E8D1C4DB9E02CC2B0AB.gr7.us-east-1.eks.amazonaws.com
database_endpoint = adm-elk-cluster.crxjg1bavqk4.us-east-1.rds.amazonaws.com:3306
wordpress_lb = adm-elk-cluster-lb-1500344054.us-east-1.elb.amazonaws.com

```

### 10. Setup wordpress site

In terraform output you can find wordpress_lb url. Please enter this url in your preferred web browser.


![Alt text](images/wp.png?raw=true "Wordpress")

### 11. Login to bastion server 

In terraform output you can find bastion public IP in bastion_public_IP section. 
Open new terminal and change aws_eks_cluster_master_key.pem permission.(Key Pair generated in section 3)

```shell
chmod 600 aws_eks_cluster_master_key.pem
```
Enter following command inorder to login bastion server. Please make sure to replace <BASTION PUBLIC IP> with public ip extracted from terraform output.

```shell
ssh -i aws_eks_cluster_master_key.pem ec2-user@<BASTION PUBLIC IP>
```

![Alt text](images/bastion.png?raw=true "Wordpress")


### 12. Login to database

If you need to login to database you should first login to bastion serve since I have controlled public access to RDS. 

Enter following command to login to RDS. Please make sure to replace <RDS ENDPOINT NAME> with terraform output value of database_endpoint.

PASSWORD :- c2LZMAk3w6LGv3dX!

```shell
mysql -u adm_master -h <RDS ENDPOINT NAME> -p
```

![Alt text](images/db.png?raw=true "Wordpress")


### 13. Configure kubectl

Login to the bastion server and Configure AWS CLI (please refer to step 3)   

```shell
$ aws eks --region us-east-1 update-kubeconfig --name adm-elk-cluster
```
 
 Test kubectl authentication

```shell
$ kubectl get nodes
```

Output

![Alt text](images/kube-nodes.png?raw=true "Wordpress")

### 14 Enable horizontal auto scaling

Login to bastion server and navigate to /home/ec2-user.

Please run follwoing command to enable HAS in kubernetes 

```shell
kubectl apply -f 1.8/
```
```shell
$ kubectl get hpa -n wordpress-ns -o wide


```

![Alt text](images/hpa.png?raw=true "Wordpress")


## Destroy infrastructure 

Please run following command to destroy infrastructure.

```shell
$ terraform destroy 
}

# Output truncated... 

Destroy complete! Resources: 82 destroyed.

```

### Known Issues in destroy

I have noticed some issues when destroying ELB. Please delete ELB manually and perform terraform destroy if you face this issue.

_____________________________________________


---------------------------------------------
### TO-DO

* ALB ingress controller to handle traffic and rule based load balancing
* SSL support for WordPress
* Configure cloudwatch logs to wordpress pods
* Configure log alerts
* Configure cloudwatch metrics alerts
* Configure CI/CD process using AWS codebuild 
* Setup ECR to store wordpress images
* Enable sticky session using ALB
* Perform performance test using jmeter

##############################################################################
############################     EKS module         ##########################
##############################################################################

module "eks" {
  # ELB should create first to attach to EKS autoscalling group. 
  depends_on      = [module.elb_http]
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.17"
  subnets         = module.vpc.private_subnets

  # Manage tags
  tags = {
    Environment = var.environment
  }

  vpc_id                          = module.vpc.vpc_id
  cluster_endpoint_private_access = false  
  cluster_endpoint_public_access  = true 
  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "echo worker group 01"
      desired_capacity          = 1
      max_size                  = 3
      min_size                  = 1
      eni_delete                    = true
      key_name                      = var.key_pair_name
      load_balancers                = ["${var.eks_cluster_name}-lb"]
      additional_security_group_ids = [aws_security_group.worker_group_mgmt.id]
    },
    {
      name                          = "worker-group-2"
      instance_type                 = "t2.medium"
      max_size                  = 3
      min_size                  = 1
      additional_userdata           = "echo worker group 02"
      eni_delete                    = true
      additional_security_group_ids = [aws_security_group.worker_group_mgmt.id]
      desired_capacity          = 1
      load_balancers                = ["${var.eks_cluster_name}-lb"]
      key_name                      = var.key_pair_name
    },
    {
      name                          = "worker-group-3"
      instance_type                 = "t2.medium"
      max_size                  = 3
      min_size                  = 1
      additional_userdata           = "echo worker group 03"
      eni_delete                    = true
      additional_security_group_ids = [aws_security_group.worker_group_mgmt.id]
      desired_capacity          = 1
      load_balancers                = ["${var.eks_cluster_name}-lb"]
      key_name                      = var.key_pair_name
    }
  ]

}

resource "aws_autoscaling_policy" "eks_asg_policy" {
  depends_on      = [module.eks]
  count = 3
  name = "eks_asg_policy"
  policy_type = "TargetTrackingScaling"
  autoscaling_group_name  = module.eks.workers_asg_names[tonumber(count.index)]
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}


##############################################################################
#########     API search to provision bastion ec2        ####################
##############################################################################


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_ami" "bastion_ami" {
  most_recent = true

  #search ami using owner
  owners = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  #filter to isolate ami
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

##############################################################################
#######################      Bastion Ec2        ##############################
##############################################################################


module "linux-bastion" {
  depends_on      = [module.vpc]
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = "${var.eks_cluster_name}-bastion"

  #Number of basion instances
  instance_count = 1

  ami                    = data.aws_ami.bastion_ami.id
  instance_type          = "t2.micro"
  key_name               = var.key_pair_name
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = module.vpc.public_subnets[0]
  user_data              = file("install_kubectl.sh")
  tags = {
    Environment = var.environment
  }
}


##############################################################################
#######################      ELB MODULE         ##############################
##############################################################################

module "elb_http" {
  depends_on      = [module.vpc]
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 2.0"

  name = "${var.eks_cluster_name}-lb"

  internal        = false
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.elb_security_group.id]
  listener = [
    {
      instance_port     = "31225"
      instance_protocol = "TCP"
      lb_port           = "80"
      lb_protocol       = "TCP"
    },
  ]

  health_check = {
    target              = "HTTP:31225/wp-admin/install.php"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = {
    Environment = var.environment
  }

  
}



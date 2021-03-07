##############################################################################
################     Bastion Security Group     ##############################
##############################################################################

#bastion security group which manage inbound and outbound traffic of bastion ec2 instance

resource "aws_security_group" "bastion" {
  name_prefix = "bastion_sg"
  vpc_id      = module.vpc.vpc_id
  description = "SSH access to manage cluster"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    description = "SSH access to bastion server"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  depends_on = [
    aws_security_group.database,
  ]  
  lifecycle {
    create_before_destroy = true
  }
}

##############################################################################
################     Database Security Group     #############################
##############################################################################


resource "aws_security_group" "database" {
  name_prefix = "rds_database_sg"
  vpc_id      = module.vpc.vpc_id
  description = "RDS database access"
  ingress {
    from_port = var.db_master_port
    to_port   = var.db_master_port
    protocol  = "tcp"
    description = "RDS database access"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }


  lifecycle {
    create_before_destroy = true
  }
}


##############################################################################
################     EKS Cluster Security Groups    ##########################
##############################################################################

resource "aws_security_group" "worker_group_mgmt" {
  name_prefix = "worker_group_mgmt_one_sg"
  vpc_id      = module.vpc.vpc_id
  description = "elk access management"
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    description = "ssh access"
    cidr_blocks = [
      module.vpc.vpc_cidr_block
    ]
  }

  ingress {
    from_port = 31225
    to_port   = 31225
    protocol  = "tcp"
    description = "wordpress node incoming traffic"
    security_groups = [
     aws_security_group.elb_security_group.id,
    ]
   
  }

  egress {
    from_port   = var.db_master_port
    to_port     = var.db_master_port
    protocol    = "tcp"
    description = "db access"
    security_groups = [
      aws_security_group.database.id,
    ]    
  }
  depends_on = [
    aws_security_group.elb_security_group,
    aws_security_group.database,
  ]
  lifecycle {
    create_before_destroy = true
  }
}

/*resource "aws_security_group" "worker_group_mgmt_two" {
  name_prefix = "worker_group_mgmt_two_sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    description = "ssh access"
    cidr_blocks = [
      "192.168.0.0/16",
    ]
  }

  ingress {
    from_port = 31225
    to_port   = 31225
    protocol  = "tcp"
    description = "wordpress node incoming traffic"
    security_groups = [
      aws_security_group.elb_security_group.id,
    ]
  }
  
  egress {
    from_port   = var.db_master_port
    to_port     = var.db_master_port
    protocol    = "tcp"
    description = "db access"
    security_groups = [
      aws_security_group.database.id,
    ]    
  }
  depends_on = [
    aws_security_group.elb_security_group,
    aws_security_group.database,
  ]
  lifecycle {
    create_before_destroy = true
  }
}*/

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management_sg"
  vpc_id      = module.vpc.vpc_id
  description = "elk access management"
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}


##############################################################################
################     ELB Cluster Security Group    ###########################
##############################################################################


resource "aws_security_group" "elb_security_group" {
  name_prefix = "${var.eks_cluster_name}-sg"
  vpc_id      = module.vpc.vpc_id
  description = "ELB security group"
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    description = "Internet access port"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }



  egress {
    from_port   = 31225
    to_port     = 31225
    protocol    = "tcp"
    description = "Worker Node two nodeport access"
    cidr_blocks = [
      module.vpc.vpc_cidr_block
    ]   
    
  }

}


resource "aws_security_group" "efs_sg" {
  name_prefix = "efs-${var.eks_cluster_name}-sg"
  vpc_id      = module.vpc.vpc_id
  description = "ELB security group"
  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    description = "NFS file system access"
    cidr_blocks = [
      module.vpc.vpc_cidr_block
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0",
    ]   
    
  }

  lifecycle {
    create_before_destroy = true
  }
}
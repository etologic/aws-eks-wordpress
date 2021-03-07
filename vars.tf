variable "region" {
  default     = "us-east-1"
  description = "AWS region"
}

variable "eks_cluster_name" {
  type    = string
  default = "adm-elk-cluster"
}

variable "vpc_name" {
  type    = string
  default = "adm-practical-interview-vpc"
}

variable "environment" {
  type    = string
  default = "adm-practical-interview"
}

variable "key_pair_name" {
  type    = string
  default = "aws_eks_cluster_master_key"
}

variable "master_db_name" {
  type    = string
  default = "databasemaster"
}


variable "db_instance_type" {
  type    = string
  default = "db.t2.small"
}

variable "db_allocated_storage" {
  type    = number
  default = 5
}

variable "db_master_port" {
  type    = number
  default = 3306
}

variable "db_master_password" {
  type    = string
  default = "c2LZMAk3w6LGv3dX!"
}

variable "db_master_username" {
  type    = string
  default = "adm_master"
}

variable "db_engine" {
  type    = string
  default = "mysql"
}

variable "db_engine_version" {
  type    = string
  default = "5.7.19"
}



locals {
  cluster_name                  = var.eks_cluster_name
  master_database_name          = "${var.master_db_name}db"
  database_monitoring_role_name = "${var.eks_cluster_name}-role"
}




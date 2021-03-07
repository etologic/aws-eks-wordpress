##############################################################################
############################     RDS module         ##########################
##############################################################################

module "db" {

  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = local.cluster_name

  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_type
  allocated_storage = var.db_allocated_storage
  multi_az          = true
  name              = local.master_database_name
  username          = var.db_master_username
  password          = var.db_master_password
  port              = var.db_master_port

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [aws_security_group.database.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  monitoring_interval    = "30"
  monitoring_role_name   = local.database_monitoring_role_name
  create_monitoring_role = true

  tags = {
    Environment = var.environment
  }

  # DB subnet group
  subnet_ids = module.vpc.private_subnets

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "amdWordpressRDS"

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}
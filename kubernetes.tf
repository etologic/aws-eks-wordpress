##############################################################################
#######################      Kubernetes provider   ###########################
##############################################################################

provider "kubernetes" {
  load_config_file       = "false"
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

##############################################################################
###################      Wordpress k8 namespace                 ##############
##############################################################################

resource "kubernetes_namespace" "wordpress-ns" {
  metadata {
    annotations = {
      name = "wordpress-ns"
    }

    labels = {
      name = "wordpress"
    }

    name = "wordpress-ns"
  }
  depends_on = [
    kubernetes_namespace.wordpress-ns
  ]
}

##############################################################################
###################      Wordpress k8 service                   ##############
##############################################################################

resource "kubernetes_service" "wordpress" {
  metadata {
    name = "wordpress"
    namespace = "wordpress-ns"
  }
  spec {
    selector = {
      app = "wordpress"
    }
    session_affinity = "ClientIP"
    port {
      node_port   = 31225
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "NodePort"
  }
  depends_on = [
    kubernetes_persistent_volume_claim.eks-pvc
  ]
}


##############################################################################
###################      Wordpress k8 deployment                 #############
##############################################################################

resource "kubernetes_deployment" "wordpress" {
  metadata {
    name = "wordpress-deployment"
    namespace = "wordpress-ns"
    labels = {
      app = "wordpress"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app  = "wordpress"
        tier = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app  = "wordpress"
          tier = "frontend"
        }
      }

      spec {
        container {
          image = "wordpress:4.8-apache"
          name  = "wordpress"
          env {
            name  = "WORDPRESS_DB_HOST"
            value = module.db.this_db_instance_endpoint
          }
          env {
            name  = "WORDPRESS_DB_USER"
            value = var.db_master_username
          }
          env {
            name  = "WORDPRESS_DB_PASSWORD"
            value = var.db_master_password
          }
          port {
            container_port = 80
            name           = "wordpress"
          }
          resources {
            limits {
              cpu    = "0.1"
              memory = "128Mi"
            }
            requests {
              cpu    = "100m"
              memory = "100Mi"
            }
          }

        }
        volume {
          name = "wordpress-persistent-storage"
          persistent_volume_claim {
            claim_name = "wp-pv-claim"
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_namespace.wordpress-ns
  ]
}

##############################################################################
###################      Wordpress PV deployment                 #############
##############################################################################

resource "kubernetes_persistent_volume" "eks_pv" {
  metadata {
    name = "tefs-pv"
  }
  spec {
    capacity = {
      storage = "20Gi"
    }
    access_modes = ["ReadWriteMany"]
    storage_class_name = "efs-sc"
    persistent_volume_reclaim_policy = "Retain"
    persistent_volume_source {
      csi {
        driver = "efs.csi.aws.com"
        volume_handle = "aws_efs_file_system.efs_storage.id "
      }
    }
  }
}

resource "kubernetes_storage_class" "eks_sc" {
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
 }

resource "kubernetes_persistent_volume_claim" "eks-pvc" {
  metadata {
    namespace = "wordpress-ns"
    name = "wp-pv-claim"
  }
  spec {
    resources {
      requests = {
        storage = "20Gi"
      }
    }
    storage_class_name = "efs-sc"
    access_modes = ["ReadWriteMany"]
  }
}



resource "kubernetes_daemonset" "eks-damonset" {
  metadata {
    name      = "efs-csi-node"
    namespace = "kube-system"
  }

  spec {
    selector {
      match_labels = {
        app = "efs-csi-node"
      }
    }

    template {
      metadata {
        labels = {
          app = "efs-csi-node"
        }
      }

      spec {
        node_selector = {
		        "kubernetes.io/os" = "linux"
	         }
	      host_network = "true"
	      priority_class_name = "system-node-critical"
        toleration  { 
  	            operator = "Exists"
	      }
        container {
          image = "amazon/aws-efs-csi-driver:latest"
          name  = "efs-plugin"
	      security_context  {
               privileged = "true"
	      }
	      args = ["--endpoint=$(CSI_ENDPOINT)","--logtostderr","--v=5"]
        env {
          name = "CSI_ENDPOINT"
          value = "unix:/csi/csi.sock"
        }
        volume_mount{
           name = "kubelet-dir"
           mount_path = "/var/lib/kubelet"
           mount_propagation = "Bidirectional"
        }
        volume_mount{
           name = "plugin-dir"
           mount_path = "/csi"
        }
        volume_mount{
           name = "efs-state-dir"
           mount_path = "/var/run/efs"
        }    
        volume_mount{
           name = "efs-utils-config"
           mount_path = "/etc/amazon/efs"
        }   
        port {
           container_port = "9809" 
           name = "healthz"
           protocol = "TCP"
        }      
        liveness_probe {
            http_get {
              path = "/healthz"
              port = "healthz"
            }
            timeout_seconds = 3
            failure_threshold = 5
            initial_delay_seconds = 10
            period_seconds        = 3
          }

        }

        container {
          image = "quay.io/k8scsi/csi-node-driver-registrar:v1.3.0"
          name  = "csi-driver-registrar"
	      args = ["--csi-address=$(ADDRESS)","--kubelet-registration-path=$(DRIVER_REG_SOCK_PATH)","--v=5"]
        env {
          name = "ADDRESS"
          value = "/csi/csi.sock"
        }
        env {
          name = "DRIVER_REG_SOCK_PATH"
          value = "/var/lib/kubelet/plugins/efs.csi.aws.com/csi.sock"
        }
        env {
          name = "KUBE_NODE_NAME"
          value_from  {
            field_ref  {
              field_path = "spec.nodeName"
            }
          }
        }
        volume_mount{
           name = "plugin-dir"
           mount_path = "/csi"
        }
        volume_mount{
           name = "registration-dir"
           mount_path = "/registration"
        }
    

        }

        container {
          image = "quay.io/k8scsi/livenessprobe:v2.0.0"
          name  = "liveness-probe"
	      args = ["--csi-address=/csi/csi.sock","--health-port=9809"]
        
        volume_mount{
           name = "plugin-dir"
           mount_path = "/csi"
        }

        }
        volume {
          name = "kubelet-dir"
          host_path {
            path = "/var/lib/kubelet"
            type = "Directory"
          }
            
        }
        volume {
          name = "registration-dir"
          host_path {
            path = "/var/lib/kubelet/plugins_registry/"
            type = "Directory"
          }
            
        }
        volume {
          name = "plugin-dir"
          host_path {
            path = "/var/lib/kubelet/plugins/efs.csi.aws.com/"
            type = "DirectoryOrCreate"
          }
        }
        volume {
          name = "efs-state-dir"
          host_path {
            path = "/var/run/efs"
            type = "DirectoryOrCreate"
          }
            
        }
        volume {
          name = "efs-utils-config"
          host_path {
            path = "/etc/amazon/efs"
            type = "DirectoryOrCreate"
          }
            
        }        
      }
    }
  }
}
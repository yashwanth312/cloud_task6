provider "kubernetes" {
    config_context_cluster = "minikube"
}

resource "kubernetes_persistent_volume_claim" "deploy-volume" {
  metadata {
    name = "wp-deploy-pvc"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "mydeploy" {
    depends_on = [
        kubernetes_persistent_volume_claim.deploy-volume,
    ]
  metadata {
    name = "wordpress-deploy"
    labels = {
      test = "task5"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        test = "task5"
      }
    }

    template {
      metadata {
        labels = {
          test = "task5"
        }
      }

      spec {
          container {
              image = "wordpress"
              name = "wp"
              volume_mount {
                  name = "myvolume"
                  mount_path = "/var/www/html"
              }
          }
          volume {
            name = "myvolume"
            persistent_volume_claim{
                  claim_name = "wp-deploy-pvc"
              }
          }
      }
    }
  }
}

resource "kubernetes_service" "expose" {
  metadata {
    name = "deploy-expose"
  }
  spec {
      selector = {
          test = "task5"
      }
    port {
      port = 80
    }

    type = "NodePort"
  }
}
provider "aws" {
	region = "ap-south-1"
	profile = "yashterra"
}

resource "aws_db_instance" "mydb" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "root"
  password             = "yashwanth"
  parameter_group_name = "default.mysql5.7"
  vpc_security_group_ids = ["sg-02845a931fda8dcc4"]
  publicly_accessible = true
  identifier = "wordpress-db"
  skip_final_snapshot = true
}

output "db-endpoint-rds" {
  value = aws_db_instance.mydb.endpoint
}
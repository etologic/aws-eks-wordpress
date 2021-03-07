terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.1"
    }
    null = {
      source = "hashicorp/null"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 2.1"
    }
    template = {
      source = "hashicorp/template"
      version = "~> 2.1"
    }
  }
}

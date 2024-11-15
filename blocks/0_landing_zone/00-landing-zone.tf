terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.8" 
    }
  }
}

provider "google" {
  region  = var.region
}

data "google_client_openid_userinfo" "me" {}
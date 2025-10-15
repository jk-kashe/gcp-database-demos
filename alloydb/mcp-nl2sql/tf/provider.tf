terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.8"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "google" {
  region = var.region
}



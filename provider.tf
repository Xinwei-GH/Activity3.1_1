provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    bucket = "sctp-ce8-tfstate"
    key    = "xinwei-activity3.1.tfstate"
    region = "ap-southeast-1"
  }
}
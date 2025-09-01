terraform {
  backend "s3" {
    bucket         = "iac-assignment-bhanu-tfstate"
    key            = "infra/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    use_lockfile   = true
  }
}
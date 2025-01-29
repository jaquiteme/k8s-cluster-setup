# AWS provider config
provider "aws" {
  region = var.region
  shared_credentials_files = ["./credentials"]
}
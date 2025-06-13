terraform {
  backend "s3" {
    bucket         = "terraform-state-data-platform"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
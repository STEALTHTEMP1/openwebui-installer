terraform {
  backend "s3" {
    bucket         = "openwebui-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "openwebui-terraform-locks"
    encrypt        = true
  }
}

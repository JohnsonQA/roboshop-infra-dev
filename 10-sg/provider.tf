# Provider file which is important to initialize terraform and configure the changes

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.98.0"
    }
  }
  
  #This backend block says, don't create state file in local instead create in s3 with below info
   backend "s3" {
    bucket = "roboshop-dev-state"  #bucketname
    key    = "roboshop-dev-sg"  # with this key state file would be created
    region = "us-east-1"
    #dynamodb_table = "lock-remote-state"  #dynamodb name. depricated
    encrypt = true
    use_lockfile = true #its a native terraform option so that no need to depend on dynamodb for locking
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}
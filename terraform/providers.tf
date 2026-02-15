provider "aws" {}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "local" {}

provider "random" {}

terraform {
  backend "s3" {
    bucket = "data-flow-tfstate"
    key    = "terraform.tfstate"
    region = "ap-northeast-1" # リージョンは後で変数化することも検討
    use_lockfile = true
  }
}

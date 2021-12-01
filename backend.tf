terraform {
  backend "s3" {
   bucket = "scdg-dsai-tfstate"
   key    = "terraform.tfstate"
   region = "ca-central-1"
  }
}
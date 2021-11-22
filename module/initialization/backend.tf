terraform {
  backend "local" {
    path = "../../data/tfstates/initialization.tfstate"
  }
  required_version = ">= 0.13.1"
}
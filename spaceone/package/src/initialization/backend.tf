terraform {
  backend "local" {
    path = "../../outputs/terraform_states/initialization.tfstate"
  }
  required_version = ">= 0.13.1"
}
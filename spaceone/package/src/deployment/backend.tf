terraform {
  backend "local" {
    path = "../../outputs/terraform_states/deployment.tfstate"
  }
  required_version = ">= 0.13.1"
}
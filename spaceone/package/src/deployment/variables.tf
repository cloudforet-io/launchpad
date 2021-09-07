variable "region" {
  type        = string
  description = "AWS Region for EKS"
}

variable "enterprise" {
  default = false
}

variable "development" {
  default = false
}

variable "notification_smpt_host" {
  default = "" 
} 

variable "notification_smpt_port" {
  default = "" 
} 

variable "notification_smpt_user" {
  default = "" 
} 

variable "notification_smpt_password" {
  default = "" 
} 
variable "region" {
  type        = string
  description = "AWS Region for EKS"
  default     = ""
}

variable "standard" {
  default = false
}

variable "minimal" {
  default = false
}

variable "internal" {
  default = false
}

variable "internal_minimal" {
  default = false
}
variable "database_user" {
  default = ""
}
variable "database_password" {
  default = ""
}
variable "database_endpoint" {
  default = ""
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
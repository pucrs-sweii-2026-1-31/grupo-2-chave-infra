variable "endpoint" {
  default = "http://localhost:4566"
}

variable "region" {
  default = "us-east-1"
}

variable "db_name" {
  default = "chave_auth"
}

variable "db_user" {
  default = "chave"
}

variable "db_password" {
  default   = "chave_secret"
  sensitive = true
}

variable "ms_auth_host" {
  default = "chave-ms-auth"
}

variable "ms_auth_port" {
  default = "3001"
}

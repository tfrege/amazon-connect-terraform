variable "account" {
  type = string
  default = "MySampleCompany"
}

variable "name" {
  type = string
  description = "Name for the Connect infrastructure"
}

variable "timezone" {
  default = "US/Mountain"
}

# Variables

variable "region" {}

variable "name" {}

variable "allow_ssh_from_v6" {
  type    = list(string)
  default = []
}

variable "allow_ssh_from_v4" {
  type    = list(string)
  default = []
}

variable "allow_icmp_from_v6" {
  type    = list(string)
  default = ["::/0"]
}

variable "allow_icmp_from_v4" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "sec_group" {
  type    = list(string)
  default = []
}

variable "server_group" {
  type    = list(string)
  default = []
}

variable "ssh_public_key" {}

variable "ssh_port" { default = 22 }

variable "node_count" { default = 1 }


variable "image_id" { default = "" }
variable "image_name" { default = "GOLD CentOS 7" }
variable "node_name" {
  default = "node"
}

variable "node_name_offset" { default = 0 }

variable "volume_name" {
  default = "vol"
}

variable "network" {
  default = "IPv6"
}

variable "az" {
  default = "default-1"
}

variable "flavor" {
  default = "m1.medium"
}

variable "zone_name" {
  description = "Only set this if you have a designate zone and want hostname A and AAAA records"
  default     = null
}

variable "domain" {
  default = "local"
}

variable "metadata" {
  type    = map(any)
  default = {}
}

variable "volume_size" {
  default = 5
}

variable "volume_type" {
  default = "rbd"
}

variable "image_user" {
  default = "centos"
}

variable "user_data" {
  type    = string
  default = null
}

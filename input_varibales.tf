variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "subnet_1_cidr_block" {
  default = "10.0.0.0/24"
}

variable "subnet_2_cidr_block" {
  default = "10.0.1.0/24"
}

variable "route_table_cidr_block" {
  default = "0.0.0.0/0"
}

variable "ami_id" {
  default = "ami-0c7217cdde317cfec"
}

variable "instance_type" {
  default = "t2.micro"
}
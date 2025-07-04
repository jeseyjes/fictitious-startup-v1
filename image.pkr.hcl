packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.2.8"
    }
    amazon-ami-management = {
      source  = "github.com/wata727/amazon-ami-management"
      version = ">= 1.0.0"
    }
  }
}

variable "version" {
  type    = string
  default = "v1.0.0"
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

locals {
  ami_name          = "cloudtalents-startup-${var.version}"
  source_ami_name   = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server*"
  source_ami_owners = ["099720109477"]
  ssh_username      = "ubuntu"
}

source "amazon-ebs" "ubuntu" {
  ami_name                    = local.ami_name
  instance_type               = "t2.micro"
  region                      = "eu-west-1"

  source_ami_filter {
    filters = {
      name                = local.source_ami_name
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = local.source_ami_owners
    most_recent = true
  }

  ssh_username                = local.ssh_username
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
}

build {
  name    = "cloudtalents_startup_ami"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "file" {
    source      = "./"
    destination = "/tmp"
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/app",
      "sudo mv /tmp/* /opt/app"
    ]
  }

  post-processor "amazon-ami-management" {
    regions       = ["eu-west-1"]
    identifier    = local.ami_name
    keep_releases = 2
  }
}

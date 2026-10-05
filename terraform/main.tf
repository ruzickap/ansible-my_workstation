terraform {
  required_version = "~> 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.67"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.6"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = merge(var.tags, { Owner = local.username })
  }
}

locals {
  availability_zone = sort(data.aws_ec2_instance_type_offerings.mac.locations)[0]
  my_public_ip_cidr = "${chomp(data.http.my_public_ip.response_body)}/32"
  username          = data.external.username.result.username

  ingress_rules = {
    for rule, port in { ssh = 22, vnc = 5900 } : rule => {
      cidr_ipv4             = local.my_public_ip_cidr
      from_port             = port
      to_port               = port
      description           = "${upper(rule)} from my laptop"
    }
  }
}

# Username of the person running Terraform, used for the Owner tag and macOS user
data "external" "username" {
  program = ["sh", "-c", "printf '{\"username\":\"%s\"}' \"$${USERNAME:-$USER}\""]
}

data "aws_ec2_instance_type_offerings" "mac" {
  location_type = "availability-zone"

  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }
}

# Most recently published Apple silicon macOS AMI
data "aws_ami" "macos" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ec2-macos-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64_mac"]
  }
}

# Public IP of the machine running Terraform (your laptop)
data "http" "my_public_ip" {
  url = "https://checkip.amazonaws.com"
}

# Public subnet only, no NAT gateway, to avoid NAT gateway costs
# trivy:ignore:AVD-AWS-0178 Flow logs not needed for a short-lived test instance
module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=b3abd6df2ecf052451a361ed55b8f06f8742a795" # v6.7.3

  name = var.name
  cidr = "10.0.0.0/24"

  azs            = [local.availability_zone]
  public_subnets = ["10.0.0.0/26"]

  enable_nat_gateway = false
  enable_vpn_gateway = false
}

# trivy:ignore:AVD-AWS-0104 Instance needs internet access (Homebrew, downloads)
module "security_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=58d8e895915f5573767081142d063b7caf7a2b47" # v6.0.0

  name        = var.name
  description = "EC2 Mac instance"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = local.ingress_rules

  egress_rules = {
    all = {
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "-1"
    }
  }
}

resource "aws_key_pair" "this" {
  key_name   = var.name
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# Password for the macOS user, required to log in via Screen Sharing (VNC)
resource "random_password" "user" {
  length           = 24
  special          = true
  override_special = "_-+="
}

# EC2 Mac requires a Dedicated Host (minimum 24h allocation, billed per second after)
# mac2.metal in us-east-1: 0.65 USD/hour -> 15.60 USD minimum per allocation
resource "aws_ec2_host" "mac" {
  instance_type     = var.instance_type
  availability_zone = local.availability_zone
  auto_placement    = "off"
  host_recovery     = "off"

  tags = {
    Name = var.name
  }
}

module "ec2_instance" {
  # checkov:skip=CKV_AWS_88:Public IP is required for SSH/VNC; inbound is limited to my IP only
  # checkov:skip=CKV_AWS_3:No additional EBS volumes are created; the root volume is encrypted
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ec2-instance.git?ref=294fb8928bc0f7e0d9ba5bea41a8236c9a7a95d9" # v6.4.1

  name = var.name

  ami           = data.aws_ami.macos.id
  instance_type = var.instance_type
  host_id       = aws_ec2_host.mac.id
  tenancy       = "host"

  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.security_group.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.this.key_name

  # First boot: create the admin user, remove Homebrew, enable Screen Sharing
  user_data_replace_on_change = false
  user_data                   = <<-EOT
    #!/bin/bash
    set -euo pipefail

    # Admin user with SSH key and password (for Screen Sharing / sudo)
    sysadminctl -addUser '${local.username}' -fullName '${local.username}' -password '${random_password.user.result}' -admin
    createhomedir -c -u '${local.username}'
    mkdir -m 700 '/Users/${local.username}/.ssh'
    echo '${trimspace(file(pathexpand(var.ssh_public_key_path)))}' > '/Users/${local.username}/.ssh/authorized_keys'
    chown -R '${local.username}:staff' '/Users/${local.username}/.ssh'

    # Remove the Homebrew preinstalled in the AMI (owned by ec2-user)
    sudo -u ec2-user NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" -- --force || true
    rm -rf /opt/homebrew

    # Screen Sharing / Remote Login only admit members of these groups when they exist
    dseditgroup -o edit -a '${local.username}' -t user com.apple.access_screensharing || true
    dseditgroup -o edit -a '${local.username}' -t user com.apple.access_ssh || true

    # Log the user in to the desktop at boot (brew services / container need a GUI session).
    # /etc/kcpassword is the password XOR-ed with Apple's fixed key, padded to a multiple of 12
    # (`sysadminctl -autologin set` fails on EC2 Mac with SACSetAutoLoginPassword error:22)
    perl -e '@k = (125, 137, 82, 35, 210, 188, 221, 234, 163, 185, 31); $p = shift; $p .= "\0" x (12 - length($p) % 12); print map { chr(ord(substr($p, $_, 1)) ^ $k[$_ % 11]) } 0 .. length($p) - 1' '${random_password.user.result}' > /etc/kcpassword
    chmod 600 /etc/kcpassword
    defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser '${local.username}'

    launchctl enable system/com.apple.screensharing
    launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist

    # Login window is already running at first boot - restart it to list the new user
    killall loginwindow || true
  EOT

  create_security_group = false

  create_iam_instance_profile = true
  iam_role_description        = "SSM access for ${var.name}"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  metadata_options = {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device = {
    size      = var.root_volume_size
    type      = "gp3"
    encrypted = true
  }
}

# Block until SSH (as the new user) and VNC are reachable - EC2 Mac boot takes ~15-20 min
resource "terraform_data" "wait_for_mac" {
  count = var.wait_for_instance ? 1 : 0

  triggers_replace = [module.ec2_instance.id]

  connection {
    host    = module.ec2_instance.public_ip
    user    = local.username
    agent   = true
    timeout = "30m"
  }

  provisioner "remote-exec" {
    inline = ["for i in $(seq 120); do nc -z localhost 5900 && exit 0; sleep 5; done; exit 1"]
  }
}

moved {
  from = terraform_data.wait_for_mac
  to   = terraform_data.wait_for_mac[0]
}

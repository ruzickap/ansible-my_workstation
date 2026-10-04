# Offline unit tests - all providers are mocked, no AWS credentials needed
# and nothing is created (a real EC2 Mac host costs at least 15.60 USD).
# Run: tofu -chdir=terraform test

mock_provider "aws" {
  mock_data "aws_ec2_instance_type_offerings" {
    defaults = {
      locations = ["us-east-1f", "us-east-1a", "us-east-1c"]
    }
  }

  mock_data "aws_ami" {
    defaults = {
      id   = "ami-0123456789abcdef0"
      name = "amzn-ec2-macos-15.0-20260101-000000-arm64"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }
}

mock_provider "http" {
  mock_data "http" {
    defaults = {
      response_body = "198.51.100.7\n"
    }
  }
}

mock_provider "external" {
  mock_data "external" {
    defaults = {
      result = {
        username = "testuser"
      }
    }
  }
}

mock_provider "random" {}

variables {
  ssh_public_key_path = "tests/fixtures/id_ed25519.pub"
}

run "defaults" {
  command = plan

  assert {
    condition     = local.availability_zone == "us-east-1a"
    error_message = "Availability zone must be the first sorted Mac-capable AZ."
  }

  assert {
    condition     = local.my_public_ip_cidr == "198.51.100.7/32"
    error_message = "Public IP must be trimmed and converted to a /32 CIDR."
  }

  assert {
    condition     = local.username == "testuser"
    error_message = "Username must come from the external data source."
  }

  assert {
    condition     = aws_ec2_host.mac.instance_type == "mac2.metal"
    error_message = "Default instance type must be mac2.metal."
  }

  assert {
    condition     = aws_ec2_host.mac.availability_zone == "us-east-1a"
    error_message = "Dedicated Host must be placed in the selected AZ."
  }

  assert {
    condition     = aws_ec2_host.mac.auto_placement == "off" && aws_ec2_host.mac.host_recovery == "off"
    error_message = "Dedicated Host auto placement and host recovery must be off."
  }

  assert {
    condition     = random_password.user.length == 24
    error_message = "User password must be 24 characters long."
  }

  assert {
    condition     = aws_key_pair.this.key_name == "macos"
    error_message = "Key pair must be named after var.name."
  }

  assert {
    condition     = startswith(aws_key_pair.this.public_key, "ssh-ed25519 ")
    error_message = "Key pair must use the provided SSH public key."
  }
}

run "security_group_limited_to_my_ip" {
  command = plan

  assert {
    condition = alltrue([
      for rule in local.ingress_rules :
      rule.cidr_ipv4 == "198.51.100.7/32"
    ]) && length(local.ingress_rules) == 2
    error_message = "Only SSH and VNC from my public IP may be allowed inbound."
  }

  assert {
    condition = toset([
      for rule in local.ingress_rules : rule.from_port
    ]) == toset([22, 5900])
    error_message = "Ingress must allow exactly ports 22 (SSH) and 5900 (VNC)."
  }
}

run "outputs" {
  command = plan

  override_module {
    target = module.ec2_instance
    outputs = {
      id        = "i-0123456789abcdef0"
      public_ip = "203.0.113.10"
    }
  }

  assert {
    condition     = output.instance_id == "i-0123456789abcdef0"
    error_message = "instance_id output is wrong."
  }

  assert {
    condition     = output.ssh_command == "ssh testuser@203.0.113.10"
    error_message = "ssh_command output is wrong."
  }

  assert {
    condition     = output.vnc_command == "open vnc://testuser@203.0.113.10"
    error_message = "vnc_command output is wrong."
  }

  assert {
    condition     = output.allowed_cidr == "198.51.100.7/32"
    error_message = "allowed_cidr output is wrong."
  }

  assert {
    condition     = output.user_password == random_password.user.result
    error_message = "user_password output must expose the generated password."
  }
}

run "custom_instance_type_and_name" {
  command = plan

  variables {
    name          = "my-mac"
    instance_type = "mac-m4.metal"
  }

  assert {
    condition     = aws_ec2_host.mac.instance_type == "mac-m4.metal"
    error_message = "Dedicated Host must use var.instance_type."
  }

  assert {
    condition     = aws_key_pair.this.key_name == "my-mac"
    error_message = "Key pair must use var.name."
  }
}

run "reject_intel_mac" {
  command = plan

  variables {
    instance_type = "mac1.metal"
  }

  expect_failures = [var.instance_type]
}

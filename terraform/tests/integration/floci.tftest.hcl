# Integration tests against Floci (local AWS emulator), nothing reaches AWS.
# Floci has no Mac instance type offerings or macOS AMIs, so those are
# overridden; VPC, security group, key pair, IAM, Dedicated Host and the
# EC2 instance are created for real in the emulator.
# Run:
#   docker run -d --rm -p 4566:4566 -v /var/run/docker.sock:/var/run/docker.sock -u root floci/floci:latest
#   tofu -chdir=terraform test -test-directory=tests/integration

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    iam = "http://localhost:4566"
    ssm = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

override_data {
  target = data.aws_ec2_instance_type_offerings.mac
  values = {
    locations = ["us-east-1a"]
  }
}

override_data {
  target = data.aws_ami.macos
  values = {
    id   = "ami-54b2a8ea54b2a8ea5"
    name = "amzn-ec2-macos-20260101"
  }
}

override_data {
  target = data.http.my_public_ip
  values = {
    response_body = "198.51.100.7\n"
  }
}

override_data {
  target = data.external.username
  values = {
    result = {
      username = "testuser"
    }
  }
}

variables {
  ssh_public_key_path = "tests/fixtures/id_ed25519.pub"
  instance_type       = "t3.micro"
  wait_for_instance   = false
}

run "apply" {
  command = apply

  assert {
    condition     = startswith(module.vpc.vpc_id, "vpc-")
    error_message = "VPC must be created."
  }

  assert {
    condition     = length(module.vpc.public_subnets) == 1
    error_message = "Exactly one public subnet must be created."
  }

  assert {
    condition     = startswith(module.security_group.id, "sg-")
    error_message = "Security group must be created."
  }

  assert {
    condition     = aws_key_pair.this.key_name == "macos"
    error_message = "Key pair must be created."
  }

  assert {
    condition     = startswith(output.instance_id, "i-")
    error_message = "EC2 instance must be created."
  }

  assert {
    condition     = output.ssh_command == "ssh testuser@${module.ec2_instance.public_ip}"
    error_message = "ssh_command output is wrong."
  }
}

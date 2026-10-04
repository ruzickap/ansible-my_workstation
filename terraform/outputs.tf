output "instance_id" {
  description = "EC2 Mac instance ID"
  value       = module.ec2_instance.id
}

output "public_ip" {
  description = "Public IP address of the Mac instance"
  value       = module.ec2_instance.public_ip
}

output "dedicated_host_id" {
  description = "Dedicated Host ID (billed for at least 24 hours)"
  value       = aws_ec2_host.mac.id
}

output "allowed_cidr" {
  description = "Your laptop's public IP - the only source allowed to reach the instance"
  value       = local.my_public_ip_cidr
}

output "ami_name" {
  description = "macOS AMI used"
  value       = data.aws_ami.macos.name
}

output "ssh_command" {
  description = "SSH to the Mac instance"
  value       = "ssh ${local.username}@${module.ec2_instance.public_ip}"
}

output "vnc_url" {
  description = "Open with Screen Sharing (password: terraform output -raw user_password)"
  value       = "vnc://${module.ec2_instance.public_ip}"
}

output "vnc_command" {
  description = "Run on your macOS laptop to open Screen Sharing (password: terraform output -raw user_password)"
  value       = "open vnc://${local.username}@${module.ec2_instance.public_ip}"
}

output "user_password" {
  description = "macOS user password for Screen Sharing login and sudo"
  value       = random_password.user.result
  sensitive   = true
}

output "ssm_session_command" {
  description = "Connect via SSM Session Manager"
  value       = "aws ssm start-session --region ${var.region} --target ${module.ec2_instance.id}"
}

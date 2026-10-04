# mac2.metal 24h cost per region (USD): us-east-1 / us-east-2 / us-west-2 15.60,
# eu-west-1 17.18, ap-southeast-1 18.70
variable "region" {
  description = "AWS region (us-east-1 has the lowest Mac pricing)"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "macos"
}

# On-Demand Dedicated Host prices (USD/hour, Oct 2026) in the cheapest regions
# us-east-1 / us-east-2 / us-west-2; minimum allocation is 24 hours:
#   mac2.metal         (M1)       0.650  ->  24h:  15.60
#   mac2-m2.metal      (M2)       0.878  ->  24h:  21.07
#   mac-m4.metal       (M4)       1.230  ->  24h:  29.52
#   mac2-m2pro.metal   (M2 Pro)   1.560  ->  24h:  37.44
#   mac-m4pro.metal    (M4 Pro)   1.970  ->  24h:  47.28
#   mac2-m1ultra.metal (M1 Ultra) 5.000  ->  24h: 120.00
#   mac-m4max.metal    (M4 Max)   6.250  ->  24h: 150.00
#   mac-m3ultra.metal  (M3 Ultra) 12.500 ->  24h: 300.00
variable "instance_type" {
  description = "Mac instance type. mac2.metal (Apple M1) is the cheapest EC2 Mac option"
  type        = string
  default     = "mac2.metal"

  # The AMI lookup and user data assume Apple silicon
  validation {
    condition     = var.instance_type != "mac1.metal"
    error_message = "Intel mac1.metal is not supported - use an Apple silicon instance type."
  }
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 100
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for the macOS user and ec2-user"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "tags" {
  description = "Tags applied to all resources (Owner is added automatically from $USERNAME)"
  type        = map(string)
  default = {
    Project   = "macos"
    ManagedBy = "terraform"
  }
}

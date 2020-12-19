variable "region" {
  type        = string
  description = "Deployment region"
  default     = "eu-west-1"
}

variable "zone" {
  type        = string
  description = "Availability zone"
  default     = "eu-west-1a"
}

variable "dedicated_instance_name" {
  type        = string
  description = "Name of the dedicated macos host"
  default     = "dedicated-mac-cf-stack"
}

variable "public_key_filename" {
  type        = string
  description = "Public key filename for the EC2 instance"
  default     = "key.pub"
}

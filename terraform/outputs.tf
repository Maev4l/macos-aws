
output "host-id" {
  value = aws_cloudformation_stack.dedicated_host.outputs["HostID"]
}

output "instance-hostname" {
  value = aws_instance.ec2_instance.public_dns
}

output "image-id" {
  value = data.aws_ami.macos.image_id
}

output "security-groupe-id" {
  value = aws_security_group.ssh.id
}

output "subnet-id" {
  value = aws_subnet.public_subnet.id
}

output "rancher-url" {
  value = ["https://${aws_eip.eip_rancher.public_ip}"]
}

output "gitlab-url" {
  value = ["http://${aws_eip.eip_gitlab.public_ip}"]
}

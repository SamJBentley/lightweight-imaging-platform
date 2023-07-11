#output "url" {
#  value = "http://${aws_instance.sam-test.private_ip}"
#}

output "vpce" {
  value = "DNS = ${element(aws_vpc_endpoint.sgw.dns_entry, 0)["dns_name"]}"
}
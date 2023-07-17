#output "url" {
#  value = "http://${aws_instance.sam-test.private_ip}"
#}

output "vpce" {
  value = "DNS = ${element(aws_vpc_endpoint.sgw.dns_entry, 0)["dns_name"]}"
}

output "smb" {
  value = "${aws_storagegateway_smb_file_share.example.path}"
}

output "fileshare" {
  value = "${aws_storagegateway_smb_file_share.example.fileshare_id}"
}

output "gateway" {
  value = aws_storagegateway_gateway.gateway.gateway_id
}
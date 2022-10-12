output "vpcid" {
    value = aws_vpc.vpc.id
}


output "zones" {
    value = data.aws_availability_zones.avai.names
}

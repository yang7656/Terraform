# public IP addresses of EC2 instances 
output "public_IP_EC2_instance1" {
    description = "The public IP of EC2 instance1"
    value = aws_instance.instance1.public_ip
}

output "public_IP_EC2_instance2" {
    description = "The public IP of EC2 instance2"
    value = aws_instance.instance2.public_ip
}

# endpoint of the RDS database
output "RDS_endpoint" {
    description = "The endpoint of RDS database"
    value = aws_db_instance.assignment_db.endpoint
}
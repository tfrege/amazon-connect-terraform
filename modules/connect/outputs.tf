output "connect_instance_id"{
    value = aws_connect_instance.instance.id
}

output "connect_instance_arn"{
    value = aws_connect_instance.instance.arn
}

output "connect_phone_number_id"{
    value = aws_connect_phone_number.phone.id
}

output "connect_phone_number_arn" {
    value = aws_connect_phone_number.phone.arn
}

output "connect_flow_id"{
    value = aws_connect_contact_flow.the_flow.contact_flow_id
}

output "connect_flow_arn"{
    value = aws_connect_contact_flow.the_flow.arn
}



output "hours_id"{
    value = aws_connect_hours_of_operation.hours.id
}

output "phone_number"{
    value = aws_connect_phone_number.phone.phone_number
}

output "flow_id" {
    value = aws_connect_contact_flow.the_flow.id  
}

output "admin_password"{
    value = random_password.password_admin.result
}
output "agent_password"{
    value = random_password.password_agent.result
}
output "backup_password"{
    value = random_password.password_backup.result
}
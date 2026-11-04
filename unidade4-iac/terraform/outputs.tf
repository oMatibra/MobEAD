output "ip_publico" {
  description = "IPv4 publico do servidor Windows Server 2019."
  value       = aws_instance.windows.public_ip
}

output "id_instancia" {
  description = "Identificador EC2 para localizar a instancia no console."
  value       = aws_instance.windows.id
}

output "url_iis" {
  description = "URL do site apos configuracao pelo Ansible."
  value       = "http://${aws_instance.windows.public_ip}/"
}

output "endereco_rdp" {
  description = "Endereco para o aplicativo Conexao de Area de Trabalho Remota."
  value       = "${aws_instance.windows.public_ip}:3389"
}

output "endereco_winrm" {
  description = "Endpoint remoto do Ansible."
  value       = "https://${aws_instance.windows.public_ip}:5986/wsman"
}

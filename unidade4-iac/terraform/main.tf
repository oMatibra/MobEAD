# Imagem publica AWS de Windows Server 2019 com interface grafica.
# O SSM publica automaticamente o ID mais recente na regiao escolhida.
data "aws_ssm_parameter" "windows_2019" {
  name = "/aws/service/ami-windows-latest/Windows_Server-2019-English-Full-Base"
}

resource "aws_vpc" "lab" {
  cidr_block           = "10.47.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "mobead-u4-vpc" }
}

resource "aws_subnet" "publica" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.47.1.0/24"
  map_public_ip_on_launch = true

  tags = { Name = "mobead-u4-subnet-publica" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "mobead-u4-igw" }
}

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "mobead-u4-rotas-publicas" }
}

resource "aws_route_table_association" "publica" {
  subnet_id      = aws_subnet.publica.id
  route_table_id = aws_route_table.publica.id
}

# NENHUMA porta de entrada liberada para 0.0.0.0/0.
# Use o IPv4 publico da maquina administradora com /32.
resource "aws_security_group" "windows" {
  name_prefix = "mobead-u4-windows-"
  description = "Laboratorio Unidade 4: RDP, WinRM TLS e IIS limitados ao IP do aluno"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "RDP (acesso remoto)"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "Ansible via WinRM HTTPS"
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "IIS HTTP para demonstracao"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    description = "Saida para atualizacoes e instalacoes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mobead-u4-sg-windows" }
}

resource "aws_instance" "windows" {
  iam_instance_profile        = aws_iam_instance_profile.ssm.name
  ami                         = data.aws_ssm_parameter.windows_2019.value
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.publica.id
  vpc_security_group_ids      = [aws_security_group.windows.id]
  associate_public_ip_address = true

  user_data                   = file("${path.module}/userdata-winrm.ps1")
  user_data_replace_on_change = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  depends_on = [aws_route_table_association.publica]
  tags       = { Name = "mobead-u4-windows2019-iis" }
}

resource "aws_iam_role" "ssm_ec2" {
  name = "mobead-u4-ssm-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "mobead-u4-ssm-instance-profile"
  role = aws_iam_role.ssm_ec2.name
}
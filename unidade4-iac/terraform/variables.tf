variable "aws_region" {
  description = "Regiao AWS onde os recursos serao criados."
  type        = string
  default     = "us-east-2"
}

variable "key_pair_name" {
  description = "Nome do par de chaves RSA criado no console EC2, na MESMA regiao."
  type        = string

  validation {
    condition     = length(trimspace(var.key_pair_name)) > 0
    error_message = "Informe o nome do par de chaves RSA da AWS."
  }
}

variable "allowed_cidr" {
  description = "Seu IPv4 publico com /32, por exemplo 203.0.113.10/32."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.allowed_cidr)) && endswith(var.allowed_cidr, "/32")
    error_message = "Informe um IPv4 valido terminado em /32 (ex.: 203.0.113.10/32)."
  }
}

variable "instance_type" {
  description = "Tipo de instancia Windows. t3.medium possui 4 GiB de RAM."
  type        = string
  default     = "t3.medium"
}

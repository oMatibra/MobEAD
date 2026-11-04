# Evidencias solicitadas pelo professor

Tire prints reais apos a execucao (nao substitua por exemplos ficticios):

1. `01-terraform-plan.png` - Terminal mostrando `terraform plan` e a criacao planejada.
2. `02-terraform-apply.png` - Terminal com `Apply complete!`.
3. `03-aws-ec2.png` - Console EC2 mostrando instancia Windows Server 2019, estado running, ID e IP.
4. `04-ansible-playbook.png` - Ubuntu/WSL mostrando PLAY RECAP com failed=0.
5. `05-iis-browser.png` - Navegador acessando `http://IP_PUBLICO/` e pagina MobEAD.
6. `06-iis-rdp.png` - Sessao RDP do Windows Server, Server Manager > IIS ou PowerShell:
   `Get-WindowsFeature -Name Web-Server` e `Get-Service W3SVC`.

Os logs reais devem ser gerados pelos comandos descritos em README.md:
- `evidencias/terraform-apply.log`
- `evidencias/ansible-execucao.log`

Antes de enviar, revise os prints e logs e oculte eventuais senhas, tokens ou chaves.

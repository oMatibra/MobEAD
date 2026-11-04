# Atividade Unidade 4 — IaC: Terraform + Ansible + AWS (Windows)

Projeto de Engenharia DevOps / MobEAD. **Esta pasta deve ser adicionada ao mesmo repositório GitHub utilizado na Unidade 2, sem substituir o Jenkinsfile nem os arquivos anteriores.**

> **Importante:** este material contém o código e os passos para executar, mas **não significa que a infraestrutura já tenha sido criada**. É necessário usar uma conta AWS própria, rodar os comandos e tirar os prints reais.
>
> **Custos:** uma EC2 Windows Server 2019 (t3.medium), o disco EBS e o IPv4 público podem gerar cobrança. Windows não deve ser presumido gratuito. Ao terminar as evidências, execute `terraform destroy`.

## O que esta atividade faz

1. **Terraform (PowerShell no Windows):** cria VPC, subnet pública, Internet Gateway, tabela de rotas, Security Group e uma EC2 com Windows Server 2019.
2. **User data (AWS):** configura automaticamente WinRM HTTPS na porta **5986** e prepara a administração via Ansible.
3. **Ansible (Ubuntu no WSL):** acessa o Windows com WinRM HTTPS, instala o IIS (`Web-Server`), abre a porta 80 no Firewall do Windows, publica uma página de validação e verifica resposta HTTP 200.
4. **GitHub + evidências:** reúna código, logs e capturas de tela e envie o link na atividade.

### Diagrama lógico

```text
Notebook Windows 10/11                         AWS (nuvem)
───────────────────────────                    ───────────────────────────────────────────
PowerShell + Terraform ──────── cria ──────────> VPC / subnet / rede / EC2 Windows 2019
Ubuntu WSL + Ansible ─────── WinRM TLS/5986 ──> Windows Server 2019
Navegador ───────────────── HTTP/80 ───────────> IIS (página MobEAD)
Área de Trabalho Remota ─── RDP/3389 ─────────> Windows Server 2019
Git local ───────────────── push ──────────────> Repositório GitHub da Unidade 2
```

As portas TCP 3389, 5986 e 80 são liberadas no **Security Group apenas para o IP público informado no `terraform.tfvars`**. É uma configuração de laboratório, não um projeto de produção (o certificado WinRM é autoassinado e a validação dele é ignorada no Ansible).

## Estrutura da pasta

```text
unidade4-iac/
├── README.md                         ← Este passo a passo
├── MODELO_ENTREGA.md                 ← Modelo do texto de envio no AVA
├── .gitignore                        ← Proteção contra envio de segredos/estado
├── terraform/
│   ├── versions.tf                   ← Provider AWS e requisitos
│   ├── variables.tf                  ← Entradas do usuário
│   ├── main.tf                       ← EC2, rede e regras
│   ├── outputs.tf                    ← IP público, URL do IIS e identificador
│   ├── terraform.tfvars.example      ← Modelo a editar
│   └── userdata-winrm.ps1            ← WinRM HTTPS no primeiro boot
├── ansible/
│   ├── requirements.yml              ← Coleções Windows
│   ├── group_vars/windows.yml        ← Senha fornecida apenas pelo ambiente
│   ├── inventory.ini.example         ← Modelo de inventário
│   └── playbook-iis.yml              ← Instalação e testes do IIS
├── scripts/
│   ├── gerar-inventario.ps1          ← Lê IP do Terraform e cria inventory.ini
│   └── verificar-portas.ps1          ← Testa 3389, 5986 e 80
└── evidencias/
    └── COMO_REGISTRAR.md             ← Lista dos prints exigidos
```

---

## PASSO 1 — Preparar a pasta do projeto no Windows

**No Explorador de Arquivos (Windows):** descompacte `unidade4-iac.zip` e coloque a pasta `unidade4-iac` **dentro do seu repositório da Unidade 2**. Exemplo:

```text
C:\DEVOPS\MobEAD\
├── Jenkinsfile
├── ... arquivos que você já tem da Unidade 2 ...
└── unidade4-iac\
    ├── terraform\
    ├── ansible\
    └── ...
```

Se seu repositório estiver em outro lugar, **adapte os caminhos dos comandos**. Os exemplos abaixo pressupõem `C:\DEVOPS\MobEAD\unidade4-iac`.

Abra **PowerShell** (não use CMD para os comandos marcados como PowerShell) e navegue até a pasta:

```powershell
cd 'C:\DEVOPS\MobEAD\unidade4-iac'
Get-ChildItem
```

**Não remova nem substitua o seu Jenkinsfile existente.** A Unidade 4 será um diretório independente dentro do mesmo repositório Git.

## PASSO 2 — Instalar Terraform e AWS CLI no Windows

Abra um **PowerShell como Administrador** e instale os programas (se já estiverem instalados, apenas confirme as versões):

```powershell
winget install --id Hashicorp.Terraform --exact
winget install --id Amazon.AWSCLI --exact
```

Feche o terminal e abra um PowerShell novo para atualizar a variável PATH:

```powershell
terraform -version
aws --version
```

Se o `winget` não funcionar, instale pelos sites oficiais:
- Terraform: https://developer.hashicorp.com/terraform/install
- AWS CLI v2: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

O Docker Desktop e o Jenkins **não são necessários para rodar esta etapa**, mas continuam no projeto da Unidade 2.

## PASSO 3 — Preparar a conta AWS e o acesso do terminal

1. Entre no console https://console.aws.amazon.com/ e escolha a região **N. Virginia / us-east-1** no topo direito (a mesma região que consta no exemplo).
2. Verifique se sua conta tem permissão para criar **VPC, subnet, rota, Internet Gateway, Security Group e EC2**, e consultar parâmetros públicos do **Systems Manager (SSM)**. Contas de laboratório podem ter restrições.
3. No PowerShell, autentique a AWS CLI. Use credenciais temporárias/SSO quando disponíveis. Em conta de laboratório com credenciais CLI fornecidas pelo professor, siga a forma de autenticação dessa conta. Se estiver usando uma conta de aprendizado com IAM Access Key:

```powershell
aws configure
```

Informe seus valores **somente no terminal local**; nunca cole chaves em prints, no GitHub ou nesta conversa. Para `Default region name` use `us-east-1`. Em seguida teste:

```powershell
aws sts get-caller-identity
```

A saída deve mostrar dados da sua conta AWS (Account / Arn / UserId), sem erro. **Não use Access Keys do usuário root.**

Se sua organização utiliza login centralizado, também pode usar `aws configure sso` e `aws sso login`. Nesse caso, antes do `terraform init`, selecione no PowerShell o perfil autenticado (troque `meu-perfil` pelo nome que configurou):

```powershell
aws sso login --profile meu-perfil
$env:AWS_PROFILE = 'meu-perfil'
aws sts get-caller-identity
```

Mantenha essa mesma sessão PowerShell ao executar Terraform.

## PASSO 4 — Criar par de chaves RSA na AWS (obrigatório)

Este passo é importante porque **o Windows Server EC2 usa a chave RSA para permitir descriptografar a senha inicial do usuário Administrator**.

1. No console AWS, abra **EC2** → menu esquerdo **Network & Security / Key Pairs (Pares de chaves)** → **Create key pair**.
2. Nome: **`mobead-unidade4`**.
3. **Key pair type: RSA** (não escolha ED25519 para Windows).
4. **Private key file format: .pem**.
5. Clique em **Create key pair**. O navegador baixará `mobead-unidade4.pem`.
6. Guarde o `.pem` em uma pasta segura, por exemplo `C:\Users\SEU_USUARIO\Documents\ChavesAWS\`, **FORA DO REPOSITÓRIO GIT**.

Não compartilhe o arquivo `.pem` nem apague o arquivo até concluir a atividade. A chave deve existir na **mesma região** da EC2 (`us-east-1`).

## PASSO 5 — Descobrir seu IP público e editar o Terraform

No **PowerShell**:

```powershell
cd 'C:\DEVOPS\MobEAD\unidade4-iac\terraform'
Copy-Item .\terraform.tfvars.example .\terraform.tfvars
(Invoke-RestMethod -Uri 'https://checkip.amazonaws.com').Trim()
notepad .\terraform.tfvars
```

O comando do IP retorna algo como `189.123.45.67` (**exemplo fictício**). No Bloco de Notas, edite o arquivo para ter o formato:

```hcl
aws_region    = "us-east-1"
key_pair_name = "mobead-unidade4"
allowed_cidr  = "SEU_IP_PUBLICO/32"
instance_type = "t3.medium"
```

**Substitua `SEU_IP_PUBLICO` pelo valor real** sem remover `/32`. Exemplo fictício: `allowed_cidr = "189.123.45.67/32"`. Salve o arquivo. Não utilize o IP de exemplo já escrito em `terraform.tfvars.example`.

> A AWS **pode cobrar** pelo servidor Windows 2019, armazenamento e IPv4. O tipo `t3.medium` foi escolhido por fornecer 4 GiB para o Windows Server; não pressuponha elegibilidade ao Free Tier. A conta deve ter meios de pagamento/quota adequados.

## PASSO 6 — Executar Terraform no PowerShell

Ainda dentro de `...\unidade4-iac\terraform`, rode **um comando de cada vez**:

```powershell
terraform init
terraform fmt
terraform validate
terraform plan -out=plano.tfplan
```

O `init` baixa o provider AWS; o `validate` verifica os arquivos; o `plan` mostra o que será criado. **Faça um print do plano (`01-terraform-plan.png`).** Se o plano não contiver a criação da EC2, não avance e verifique os erros.

Para criar de fato (isso gera custos na conta AWS):

```powershell
terraform apply .\plano.tfplan | Tee-Object -FilePath ..\evidencias\terraform-apply.log
```

Quando funcionar, a saída terá `Apply complete!` e apresentará os outputs. **Guarde o print (`02-terraform-apply.png`) e o log gerado.**

Descubra o IP, ID e a URL:

```powershell
terraform output
terraform output -raw ip_publico
terraform output -raw url_iis
```

**Importante:** o Terraform terminou quando a EC2 foi **criada**, mas o **Windows ainda pode estar inicializando**. A configuração inicial de WinRM ocorre no primeiro boot. No console AWS → **EC2 / Instances**, espere a instância mostrar `running` e os `Status checks` concluídos; a obtenção da senha Windows pode demorar após a inicialização.

Se quiser validar o parâmetro de imagem antes de criar:

```powershell
aws ssm get-parameter --name '/aws/service/ami-windows-latest/Windows_Server-2019-English-Full-Base' --region us-east-1 --query Parameter.Value --output text
```

## PASSO 7 — Conferir a instância no console AWS

1. Acesse **EC2 → Instances / Instâncias** e escolha **us-east-1**.
2. Procure `mobead-u4-windows2019-iis`.
3. Confirme `Instance state = Running`, o sistema Windows Server 2019 (informação da AMI) e o **Public IPv4 address**.
4. Tire o print `03-aws-ec2.png`. O identificador também está em `terraform output -raw id_instancia`.

O diagrama da atividade solicita acesso RDP 3389 e WinRM 5986: o Terraform já libera essas portas **somente para o IP informado** e o user data prepara o serviço WinRM.

## PASSO 8 — Obter a senha inicial do Windows Server 2019

No console **EC2 → Instances**:

1. Selecione a EC2 `mobead-u4-windows2019-iis`.
2. Clique em **Actions / Ações → Security / Segurança → Get Windows password / Obter senha do Windows** (a posição varia conforme a interface do console).
3. Envie o **arquivo privado `mobead-unidade4.pem`** guardado fora do Git.
4. Escolha **Decrypt Password / Descriptografar senha**.
5. Copie a senha para um local seguro. O usuário geralmente é **`Administrator`**.

Se aparecer mensagem de senha ainda indisponível, a inicialização do Windows ainda não terminou: volte a esta tela após a instância concluir o primeiro boot. **Jamais salve a senha em `inventory.ini`, `.tfvars`, Jenkinsfile ou no GitHub.**

## PASSO 9 — Habilitar WSL e Ubuntu no Windows para o Ansible

**O Terraform roda diretamente no Windows.** O **Ansible controlador** será instalado no **Ubuntu do WSL**, mas o servidor de destino continuará sendo **Windows Server 2019 na AWS**.

Em PowerShell **como Administrador**:

```powershell
wsl --install -d Ubuntu
```

Se for solicitada reinicialização, reinicie o Windows, abra **Ubuntu** pelo menu Iniciar e faça o cadastro inicial do usuário Linux. Se o WSL já estiver instalado:

```powershell
wsl --list --verbose
```

Depois, na janela **Ubuntu** (com prompt similar a `usuario@PC:~$`, **não** na janela `PS C:\>`), execute:

```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv
python3 -m venv ~/venvs/ansible-unidade4
source ~/venvs/ansible-unidade4/bin/activate
python -m pip install --upgrade pip
python -m pip install 'ansible-core>=2.17,<2.20' 'pywinrm>=0.4.0'
ansible --version
```

Depois vá para a pasta de Ansible no repositório (atenção ao caminho Windows/WSL):

```bash
cd /mnt/c/DEVOPS/MobEAD/unidade4-iac/ansible
ansible-galaxy collection install -r requirements.yml
```

Se sua pasta Windows for diferente, adapte `/mnt/c/DEVOPS/MobEAD/...` para o caminho usado no seu PC. Para evitar caminhos longos ou com caracteres especiais, mantenha o projeto em uma pasta simples.

Se estiver repetindo a atividade outro dia, ative o ambiente virtual novamente com `source ~/venvs/ansible-unidade4/bin/activate`.

## PASSO 10 — Gerar automaticamente o inventário do Ansible

**Volte ao PowerShell do Windows** (não ao Ubuntu), vá para a raiz da Unidade 4 e rode:

```powershell
cd 'C:\DEVOPS\MobEAD\unidade4-iac'
.\scripts\gerar-inventario.ps1
```

Se o PowerShell bloquear o script com a mensagem de política de execução, rode **apenas nessa sessão**:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\gerar-inventario.ps1
```

O arquivo `ansible\inventory.ini` será criado com o IP real obtido do `terraform output`. **Não precisa editar IP manualmente**. Esse arquivo é ignorado no Git. Exemplo do conteúdo:

```ini
[windows]
windows2019 ansible_host=SEU_IP_PUBLICO

[windows:vars]
ansible_user=Administrator
ansible_connection=winrm
ansible_port=5986
ansible_winrm_scheme=https
ansible_winrm_transport=basic
ansible_winrm_server_cert_validation=ignore
ansible_winrm_operation_timeout_sec=60
ansible_winrm_read_timeout_sec=70
```

Teste as portas ainda no PowerShell:

```powershell
.\scripts\verificar-portas.ps1
```

A porta **5986** deve estar acessível antes do primeiro comando Ansible. A porta **80** só estará pronta após a instalação do IIS. Se 5986 estiver fechada, veja a seção **Problemas comuns**.

## PASSO 11 — Testar conexão WinRM a partir do Ubuntu (WSL)

**Volte para a janela Ubuntu/WSL** e, se necessário, ative o virtualenv:

```bash
source ~/venvs/ansible-unidade4/bin/activate
cd /mnt/c/DEVOPS/MobEAD/unidade4-iac/ansible
```

Digite este comando para inserir a senha Windows **sem exibi-la na tela e sem salvá-la no repositório**:

```bash
read -rsp 'Cole a senha do Administrator da AWS e pressione Enter: ' WINDOWS_ADMIN_PASSWORD; echo
export WINDOWS_ADMIN_PASSWORD
```

**Agora sim** teste o WinRM:

```bash
ansible -i inventory.ini windows -m ansible.windows.win_ping
```

Resultado esperado, após conexão bem-sucedida:

```text
windows2019 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Isso **não é** um ping ICMP comum; testa a capacidade do Ansible executar módulo remoto no Windows. Se falhar, verifique a senha, o Security Group com seu IP atual, o estado do Windows e o listener HTTPS.

## PASSO 12 — Rodar o playbook Ansible e registrar log

No **Ubuntu/WSL**, ainda dentro da pasta `ansible`, com o ambiente virtual e `WINDOWS_ADMIN_PASSWORD` ativos:

```bash
set -o pipefail
ansible-playbook -i inventory.ini playbook-iis.yml 2>&1 | tee ../evidencias/ansible-execucao.log
```

O playbook executa:

1. Confirma que a senha foi fornecida na sessão do WSL.
2. Aguarda o WinRM HTTPS/5986 e executa `win_ping`.
3. Instala IIS (`Web-Server`) e suas ferramentas de administração.
4. Reinicia o servidor **apenas se solicitado** pela instalação.
5. Libera a porta HTTP/80 no Firewall do Windows.
6. Inicia o serviço `W3SVC` automaticamente.
7. Cria uma página `C:\inetpub\wwwroot\index.html`.
8. Testa `http://127.0.0.1/` e exige **HTTP 200** e presença do texto `MobEAD`.
9. Mostra as informações de instalação do IIS no terminal.

A execução correta termina com **`PLAY RECAP` e `failed=0`**. Salve print `04-ansible-playbook.png` junto com `ansible-execucao.log`.

É possível executar o playbook mais de uma vez; tarefas de instalação/configuração foram escolhidas para serem idempotentes.

Após terminar, remova a senha do ambiente da sessão:

```bash
unset WINDOWS_ADMIN_PASSWORD
```

## PASSO 13 — Conferir IIS no navegador Windows

No **PowerShell do Windows**:

```powershell
cd 'C:\DEVOPS\MobEAD\unidade4-iac\terraform'
terraform output -raw url_iis
```

Copie a URL, que será algo como `http://SEU_IP_PUBLICO/`, e abra no Chrome ou Edge do Windows. A página deverá conter:

```text
MobEAD - Unidade 4
Infraestrutura como Codigo (IaC)
Windows Server 2019 provisionado por Terraform.
Servidor IIS instalado e configurado pelo Ansible.
Status: ONLINE | HTTP 200
```

**Faça o print `05-iis-browser.png`** com a URL e o conteúdo visíveis. O site utiliza **HTTP** apenas para a página demonstrativa, sem transmissão de credenciais; a comunicação administrativa WinRM usa **HTTPS 5986**.

## PASSO 14 — Entrar na VM Windows via RDP e conferir o IIS

No Windows local:

1. Pressione **Win + R**, digite `mstsc` e pressione Enter.
2. No campo **Computador**, digite o IP público retornado em `terraform output -raw ip_publico`.
3. Conecte-se com usuário **Administrator** e senha descriptografada na AWS.
4. Se o Windows mostrar aviso de certificado de RDP autoassinado, confirme **somente após verificar o IP da sua instância**.
5. Na VM, abra o **Server Manager → Add roles and features** ou **IIS Manager** e confira o papel do Web Server. Alternativamente, abra PowerShell **dentro da VM** e execute:

```powershell
Get-WindowsFeature -Name Web-Server
Get-Service W3SVC
Get-NetTCPConnection -LocalPort 80 -State Listen
Get-Content 'C:\inetpub\wwwroot\index.html' | Select-Object -First 8
```

A função `Web-Server` deve aparecer como instalada e o serviço `W3SVC` como `Running`. Tire o print `06-iis-rdp.png`.

Você pode consultar o log do user data **dentro da EC2**:

```powershell
Get-Content 'C:\Temp\unidade4-winrm-setup.log' -Tail 50
winrm enumerate winrm/config/listener
```

Isso comprova a configuração WinRM no primeiro boot.

## PASSO 15 — Enviar para o GitHub do projeto da Unidade 2

**Depois de executar e registrar as evidências**, volte para o PowerShell do Windows, na pasta **raiz do repositório Git da Unidade 2** (exemplo `C:\DEVOPS\MobEAD`):

```powershell
cd 'C:\DEVOPS\MobEAD'
git status
git add unidade4-iac
git status
git commit -m "Unidade 4 - IaC Terraform AWS Windows e Ansible IIS"
git push
```

O `git status` deve mostrar que os `.tf`, `.yml`, scripts, README e **evidências reais** foram adicionados, mas **não** os arquivos secretos `.pem`, `terraform.tfvars`, `inventory.ini`, `.tfstate` nem `*.tfplan`.

Se seu repositório foi **clonado do professor** e você não tem permissão de escrita, use **Fork** para sua conta (ou seu próprio repositório), coloque a pasta `unidade4-iac` lá e faça o push na sua cópia. Não é necessário modificar o repositório do professor.

No AVA, entregue o **link da pasta do repositório** e um texto como `MODELO_ENTREGA.md`, indicando os prints e logs. **Verifique o link público ou o acesso que o professor terá** antes de enviar.

## PASSO 16 — Evitar custos: destruir os recursos depois dos prints

Quando tiver os prints e logs, execute no **PowerShell**:

```powershell
cd 'C:\DEVOPS\MobEAD\unidade4-iac\terraform'
terraform destroy
```

Digite `yes` para confirmar **após conferir o plano de destruição**. Aguarde a saída `Destroy complete!`. Isso remove os recursos gerenciados pelo Terraform neste projeto, incluindo a EC2, a VPC e as regras, e evita novas cobranças **desses recursos**. A chave RSA criada manualmente no console é um recurso à parte; se não precisar dela, remova-a manualmente no console EC2. Verifique também a seção de custos/cobranças na AWS.

**Não destrua antes de capturar e registrar as evidências**, porque o navegador e o RDP deixarão de funcionar.

---

## Problemas comuns e como diagnosticar

| Sintoma | Possível causa e ação |
|---|---|
| `terraform` não reconhecido | Abra um PowerShell novo após a instalação; confira PATH e `terraform -version`. |
| `aws sts get-caller-identity` falha | Conta/credenciais/perfil inválidos ou expirados; autentique novamente. |
| `InvalidKeyPair.NotFound` | Par RSA não existe **na mesma região** definida em `aws_region` ou nome incorreto. |
| `AccessDenied`, `UnauthorizedOperation` | IAM ou conta de laboratório bloqueia serviços/rede; é preciso autorização AWS apropriada. |
| `InsufficientInstanceCapacity` / quotas | Tipo de instância não disponível/quota de vCPUs insuficiente; ajuste região ou solicite quota. |
| `terraform plan` acusa erro no `allowed_cidr` | Use IPv4 público real e `/32`, ex.: `203.0.113.10/32` (exemplo fictício). |
| `Get Windows Password` indisponível | Windows ainda concluindo o primeiro boot; aguarde terminar e tente novamente. |
| 3389/5986 não acessíveis | Revise Security Group, IP atual (VPN, mudança de rede, CGNAT), firewall Windows e user data. |
| WinRM `connection timeout` | Aguarde a inicialização do EC2Launch e confira `C:\Temp\unidade4-winrm-setup.log` via RDP. |
| WinRM `401 Unauthorized` | Senha Windows incorreta, não exportada no WSL ou usuário diferente; reinsira `read -rsp ...`. |
| Ansible falha em certificado SSL | Confirme `ansible_winrm_server_cert_validation=ignore` no inventário e TLS 5986 na EC2; **somente para laboratório**. |
| `No module named winrm` | No WSL ative o virtualenv e instale `python -m pip install pywinrm`. |
| `couldn't resolve module community.windows.win_firewall_rule` | Reinstale coleções no WSL com `ansible-galaxy collection install -r requirements.yml`. |
| Browser não abre IIS, mas Ansible passou | Confira porta 80 no Security Group, IP atual, Windows Firewall, URL **http**, e serviço `W3SVC`. |
| `git push` sem permissão | Seu clone pode apontar para o repositório do professor. Faça fork e envie para o próprio repositório. |

### Se o seu IP público mudar durante a atividade

No Windows, obtenha o novo IP:

```powershell
(Invoke-RestMethod -Uri 'https://checkip.amazonaws.com').Trim()
```

Edite `terraform\terraform.tfvars` atualizando `allowed_cidr = "NOVO_IP/32"` e, em `terraform`, execute:

```powershell
terraform plan
terraform apply
```

Isso deve atualizar as regras do Security Group sem precisar apagar a EC2 (desde que só essa variável mude). Se acessar por VPN, considere também o IP que a AWS realmente verá como origem.

### Documentações oficiais de apoio

- AWS: https://docs.aws.amazon.com/pt_br/AWSEC2/latest/UserGuide/user-data.html
- AWS: https://docs.aws.amazon.com/pt_br/AWSEC2/latest/UserGuide/create-key-pairs.html
- AWS: https://repost.aws/pt/knowledge-center/retrieve-windows-admin-password
- AWS SSM AMI: https://docs.aws.amazon.com/pt_br/systems-manager/latest/userguide/parameter-store-public-parameters-ami.html
- Terraform: https://developer.hashicorp.com/terraform/docs
- Ansible WinRM: https://docs.ansible.com/projects/ansible/latest/os_guide/windows_winrm.html
- Ansible IIS: https://docs.ansible.com/projects/ansible/latest/collections/ansible/windows/win_feature_module.html
- Ansible Firewall: https://docs.ansible.com/projects/ansible/latest/collections/community/windows/win_firewall_rule_module.html

**Critério de conclusão:** `Terraform apply complete` + instância AWS Windows 2019 existente + `Ansible PLAY RECAP failed=0` + IIS instalado e acessível via navegador + link do GitHub com códigos e provas reais.

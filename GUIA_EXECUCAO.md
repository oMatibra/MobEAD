# Passo a passo completo — Jenkins + SonarQube + MobEAD

Tutorial pensado para **Windows 10/11, PowerShell, Git e Docker Desktop com containers Linux/WSL2**. Tambem funciona em Linux, ajustando os comandos do terminal.

## 1. Preparar o computador

- Instale **Git for Windows** e **Docker Desktop** (Linux containers / engine WSL2).
- Abra o Docker Desktop e aguarde a indicacao de que esta em execucao.
- Reserve aproximadamente **8 GB ou mais de RAM disponivel para Docker**, 2+ nucleos de CPU e espaco em disco; o SonarQube sozinho costuma requerer cerca de 4 GB.
- Abra o PowerShell na pasta onde quer armazenar o projeto.

Confirme que os comandos funcionam:

```powershell
git --version
docker --version
docker compose version
docker info
```

Se `docker info` falhar, inicie o Docker Desktop antes de prosseguir.

## 2. Fazer o fork e colocar os arquivos no GitHub

1. Acesse https://github.com/osanam-giordane/MobEAD e clique em **Fork**; crie o fork na sua conta.
2. Clone **seu fork** (substitua `SEU_USUARIO`):

```powershell
git clone https://github.com/SEU_USUARIO/MobEAD.git
cd MobEAD
```

3. Extraia o ZIP fornecido e copie os arquivos da pasta do projeto do ZIP para a pasta `MobEAD` que voce acabou de clonar, substituindo os arquivos repetidos. Inclua `.dockerignore` e remova o `teste.js` antigo da pasta clonada. **Nao copie uma pasta `.git` de outro repositorio.**
4. Envie o pipeline e os testes para seu fork:

```powershell
git add -A
git commit -m "feat: pipeline Jenkins SonarQube com testes e deploy dev prod"
git push -u origin main
```

Se o Git exigir identificacao, configure seu nome e e-mail antes do commit. Se seu branch principal nao se chama `main`, use seu nome real de branch.

**Guarde um print** da pagina do seu fork mostrando `Jenkinsfile`, `docker-compose.yml`, `mobead.test.cjs` e `sonar-project.properties`.

## 3. Subir o laboratorio em Docker

No PowerShell, dentro da pasta `MobEAD`, rode:

```powershell
docker compose up -d --build
docker compose ps
```

Na primeira vez, o Docker baixa imagens e cria o Jenkins, o SonarQube e o banco PostgreSQL; isso pode demorar alguns minutos. Aguarde os servicos iniciarem.

Abra no navegador:

- Jenkins: http://localhost:8080
- SonarQube: http://localhost:9000

Se o SonarQube ainda nao abrir, espere e confira:

```powershell
docker compose logs --tail 100 sonarqube
docker compose logs --tail 100 postgres
```

## 4. Primeira configuracao do Jenkins

1. Pegue a senha inicial no PowerShell:

```powershell
docker exec mobead-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

2. Em http://localhost:8080, cole a senha, avance e crie seu usuario administrador.
3. Se aparecer uma tela de instalacao, conclua com os plugins sugeridos. O Dockerfile do projeto ja inclui os plugins essenciais **Pipeline**, **Git**, **Pipeline: Input Step**, **Pipeline Stage View** e **SonarQube Scanner for Jenkins**.
4. Escolha a URL do Jenkins `http://localhost:8080/` para acesso no seu computador.

## 5. Configurar o SonarQube

1. Em http://localhost:9000, entre com usuario **admin** e senha inicial **admin** e altere a senha quando solicitado.
2. Em **My Account > Security**, crie um token de analise, por exemplo `jenkins-mobead`. Copie o token temporariamente: ele nao aparece novamente.
3. No Jenkins, entre em **Manage Jenkins > Credentials > System > Global credentials > Add Credentials** (a navegacao pode variar por versao):
   - **Kind:** Secret text
   - **Secret:** token gerado no SonarQube
   - **ID:** `sonarqube-token`
   - **Description:** `Token SonarQube MobEAD`
4. Va a **Manage Jenkins > System > SonarQube servers > Add SonarQube**:
   - **Name:** `sonarqube-local` (exatamente esse nome)
   - **Server URL:** `http://sonarqube:9000` (**nao** localhost dentro do container)
   - **Server authentication token:** escolha `sonarqube-token`
   - Salve.
5. No SonarQube, acesse **Administration > Configuration > Webhooks** e crie um webhook:
   - **Name:** `jenkins-mobead`
   - **URL:** `http://mobead-jenkins:8080/sonarqube-webhook/`
   - A **barra final `/` e obrigatoria**.

Voce nao precisa instalar manualmente o SonarScanner no Windows: o Jenkins executa a imagem de scanner pelo Docker.

## 6. Criar a pipeline com o seu nome

1. No Jenkins, clique em **New Item**.
2. Digite **`Matibra-CI-CD-MobEAD`** e escolha **Pipeline**.
3. Opcional: em **Build Triggers**, ative **Poll SCM** e informe `H/5 * * * *` para consultar novos commits no GitHub aproximadamente a cada cinco minutos (adequado ao laboratorio local, que nao recebe webhooks publicos).
4. Em **Pipeline**:
   - **Definition:** `Pipeline script from SCM`
   - **SCM:** `Git`
   - **Repository URL:** `https://github.com/SEU_USUARIO/MobEAD.git`
   - **Credentials:** vazio, se seu fork for publico
   - **Branches to build:** `*/main` (ou o branch principal real)
   - **Script Path:** `Jenkinsfile`
5. Clique **Save** e **Build Now**.

O Jenkins executa automaticamente o checkout, os 7 testes, a conversao do relatorio de testes, analise SonarQube, Quality Gate, build Docker, deploy DEV e verificacao HTTP.

## 7. Aprovar producao e acompanhar

1. Aguarde chegar em **`08 - Aprovacao para producao`**.
2. **Tire um print** da tela solicitando autorizacao para deploy em producao.
3. Clique em **Aprovar deploy PRODUCAO**. Sem essa autorizacao, a publicacao em producao nao ocorre.
4. Aguarde os stages 09 e 10 ficarem verdes.
5. Visite e teste a aplicacao em:
   - **DEV:** http://localhost:8081
   - **PROD:** http://localhost:8082
6. No Jenkins, abra a execucao e clique em **Console Output**. Perto do final, procure `PIPELINE MATIBRA: SUCESSO!` e `Finished: SUCCESS`.
7. No menu **Artifacts**, baixe `tests.tap`, `sonar-tests.xml`, `evidencias/resumo-execucao.txt` e os logs de containers. **O log completo e o console da execucao no Jenkins**.
8. No SonarQube, abra o projeto `MobEAD - Matibra - Unidade 2` e verifique o **Quality Gate**, as analises e os testes importados.

## 8. Quais prints tirar para entregar

1. **GitHub:** seu fork aberto, com o `Jenkinsfile` e os arquivos adicionados.
2. **Jenkins Stage View:** nome `Matibra-CI-CD-MobEAD`, todos os stages concluídos em verde.
3. **SonarQube:** projeto `MobEAD - Matibra - Unidade 2`, resultado da analise e Quality Gate.
4. **Jenkins Console Output:** linhas finais dos testes e `Finished: SUCCESS`.
5. **Solicitacao de aprovacao:** stage 08 antes de clicar no botao.
6. **Aplicacao DEV:** navegador em `http://localhost:8081` com o simulado funcionando.
7. **Aplicacao PROD:** navegador em `http://localhost:8082` com o simulado funcionando.
8. **Git:** terminal mostrando seus comandos/ultimo commit e seu usuario no fork.

Cole as capturas verdadeiras no seu documento final usando os campos do `RELATORIO_ENTREGA.md`. Nao use prints inventados ou do computador de outra pessoa.

## 9. Testar apenas os testes ou a imagem

Se voce tiver Node.js 22+ instalado, sem Jenkins:

```powershell
node --test mobead.test.cjs
```

Com Docker instalado, para testar a imagem isoladamente (opcional):

```powershell
docker build -t mobead-teste-local .
docker run --rm -d --name mobead-teste -p 8083:80 mobead-teste-local
```

Abra http://localhost:8083. Para parar esse container de teste:

```powershell
docker stop mobead-teste
```

## 10. Erros comuns e solucao

- **`docker: command not found` / `docker info` falhou:** instale/inicie o Docker Desktop em modo Linux.
- **Porta 8080, 8081, 8082 ou 9000 ocupada:** pare o outro programa que usa a porta ou ajuste os mapeamentos e a documentacao (os ports DEV/PROD tambem estao no `Jenkinsfile`).
- **SonarQube nao inicia:** verifique `docker compose logs sonarqube`, RAM e limites Linux do Elasticsearch. Em Linux, o parametro `vm.max_map_count` deve atender aos requisitos do SonarQube; a documentacao do SonarQube Community Build orienta usar pelo menos `524288`.
- **`withSonarQubeEnv: installation not found`:** o nome cadastrado no Jenkins deve ser exatamente `sonarqube-local`.
- **Quality Gate expira:** confirme que o webhook do SonarQube usa `http://mobead-jenkins:8080/sonarqube-webhook/`, com a barra final, e que o Jenkins responde na rede Docker.
- **Testes nao aparecem no SonarQube:** confirme que o stage 02 gerou `sonar-tests.xml` antes do stage 03; ele e importado por `sonar.testExecutionReportPaths`.
- **Sem checkout do GitHub:** confira a URL do **seu fork**, visibilidade publica e branch configurado (`*/main`).
- **Stages 09/10 nao executam:** e necessario clicar em **Aprovar deploy PRODUCAO** no Jenkins.
- **Qualidade rejeitada:** isso significa que o Quality Gate falhou; consulte os problemas identificados no SonarQube. O pipeline deve parar neste caso.

Para interromper os servicos **preservando seus dados e configuracoes**, use `docker compose stop` (nao `docker compose down -v`). Os containers DEV/PROD criados pelo Jenkins podem ser parados separadamente com `docker stop mobead-dev mobead-prod`.

## Referencias tecnicas

- Jenkins: https://www.jenkins.io/doc/book/pipeline/
- Aprovacao humana: https://plugins.jenkins.io/pipeline-input-step/
- Integracao SonarQube/Jenkins: https://www.jenkins.io/doc/pipeline/steps/sonar/
- Importacao generica de testes: https://docs.sonarsource.com/sonarqube-community-build/analyzing-source-code/test-coverage/test-execution-parameters
- SonarScanner CLI: https://docs.sonarsource.com/sonarqube-community-build/analyzing-source-code/scanners/sonarscanner

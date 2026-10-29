# Relatorio de atividade — Unidade 2: Pipeline CI/CD

**Aluno:** Matibra (substituir pelo nome completo exigido pela instituicao)

**Disciplina:** Engenharia DevOps — Unidade 2

**Projeto:** MobEAD, fork do repositorio de Osanam Giordane

**Nome do pipeline:** `Matibra-CI-CD-MobEAD`

**Link do meu fork:** `https://github.com/SEU_USUARIO/MobEAD` (preencher apos publicar)

## 1. Objetivo

Implementar uma pipeline de integracao e entrega continuas usando Git/GitHub, Jenkins, testes automatizados, SonarQube e Docker, com implantacao em ambiente de desenvolvimento e producao mediante solicitacao de liberacao manual.

## 2. Arquitetura executada pelo pipeline

| Etapa | Atividade | Verificacao esperada |
| --- | --- | --- |
| 01 | Checkout no fork GitHub | Hash do commit no console |
| 02 | Sete testes Node.js | Resultado TAP e XML SonarQube |
| 03 | Analise SonarQube | Projeto `mobead-matibra` |
| 04 | Quality Gate | Status aprovado ou interrompe a pipeline |
| 05 | Docker build | Imagem `mobead-matibra:NUMERO_DA_BUILD` |
| 06 | Deploy DEV | Site em http://localhost:8081 |
| 07 | Smoke test DEV | HTTP 200 e conteudo do site |
| 08 | Aprovacao producao | Confirmacao humana obrigatoria |
| 09 | Deploy PROD | Site em http://localhost:8082 |
| 10 | Smoke test PROD | HTTP 200 e conteudo do site |

## 3. Testes

Os testes automatizados verificam carregamento de simulados, navegacao, aprovacao por pontuacao, reprovacao, selecao de alternativas, referencias de arquivos no HTML e sintaxe dos arquivos JavaScript da aplicacao. Sao **7 casos**; em validacao local por Node.js, os 7 passaram. Esta verificacao local nao substitui a execucao completa no Jenkins.

O SonarQube recebe o XML de execucao `sonar-tests.xml` e avalia o codigo do aplicativo, excluindo bibliotecas externas legadas da analise de fontes.

## 4. Evidencias da execucao (preencher com prints reais)

**Figura 1 — Fork e arquivos do projeto no GitHub**

[INSERIR PRINT REAL APOS FAZER O FORK/PUSH]

**Figura 2 — Jenkins: visao da pipeline Matibra-CI-CD-MobEAD concluida**

[INSERIR PRINT REAL DOS STAGES VERDES]

**Figura 3 — SonarQube: resultado da analise e Quality Gate**

[INSERIR PRINT REAL DO PROJETO]

**Figura 4 — Solicitação de aprovacao para producao**

[INSERIR PRINT REAL DO STAGE 08 ANTES DE APROVAR]

**Figura 5 — Jenkins: Console Output final**

[INSERIR PRINT REAL MOSTRANDO Finished: SUCCESS]

**Figura 6 — MobEAD em ambiente de desenvolvimento**

[INSERIR PRINT REAL DE http://localhost:8081]

**Figura 7 — MobEAD em ambiente de producao**

[INSERIR PRINT REAL DE http://localhost:8082]

**Figura 8 — Git: comandos executados e ultimo commit**

[INSERIR PRINT REAL DO TERMINAL]

## 5. Comandos Git

O arquivo separado `COMANDOS_GIT.md` registra os comandos utilizados na preparacao e os comandos que precisam ser executados pelo aluno no seu proprio fork.

## 6. Conclusao (preencher apenas apos rodar)

**Resultado final no Jenkins:** [PREENCHER: SUCCESS / FAILURE]

**Data de execucao:** [PREENCHER]

**Numero da build:** [PREENCHER]

**Quality Gate:** [PREENCHER]

**Aprovacao de producao realizada por:** [PREENCHER]

**Observacoes:** [DESCREVER O QUE FOI CONFERIDO EM DEV E PROD]

> Nao declarar sucesso do Jenkins, SonarQube ou deploy antes da execucao efetiva. As capturas de tela e logs de servicos precisam ser obtidos do ambiente real.

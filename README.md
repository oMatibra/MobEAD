# MobEAD — Pipeline CI/CD Matibra (Unidade 2)

Projeto original: https://github.com/osanam-giordane/MobEAD

Este pacote acompanha o aplicativo MobEAD original, adaptado para um laboratorio **Jenkins + GitHub + Node.js + SonarQube + Docker**.

## O que esta implementado

1. Checkout do fork no GitHub.
2. Sete testes automatizados da logica do MobEAD e validacao dos arquivos estaticos.
3. Conversao do resultado de testes para XML generico, importado pelo SonarQube.
4. Analise do SonarQube e Quality Gate obrigatorio.
5. Build de uma unica imagem Nginx do site.
6. Deploy automatico em **desenvolvimento** e smoke test HTTP.
7. Aprovacao humana obrigatoria antes de **producao**.
8. Deploy da mesma imagem em producao e smoke test HTTP.
9. Arquivamento de logs e relatorios no Jenkins.

O nome do job solicitado e **Matibra-CI-CD-MobEAD**.

## Comece por aqui

- **[GUIA_EXECUCAO.md](GUIA_EXECUCAO.md)**: tutorial detalhado para Windows + Docker Desktop.
- **[COMANDOS_GIT.md](COMANDOS_GIT.md)**: comandos Git para entregar ao professor.
- **[RELATORIO_ENTREGA.md](RELATORIO_ENTREGA.md)**: resumo da atividade e checklist dos prints reais.

## Enderecos depois de executar o Jenkins

| Servico | URL |
| --- | --- |
| Jenkins | http://localhost:8080 |
| SonarQube | http://localhost:9000 |
| MobEAD DEV | http://localhost:8081 |
| MobEAD PROD | http://localhost:8082 |

**Importante:** estes enderecos so funcionam apos iniciar os containers, configurar o Jenkins/SonarQube, executar o pipeline e aprovar a etapa de producao. Este pacote e um laboratorio local; o acesso ao socket Docker e as credenciais simples de PostgreSQL nao sao adequados para producao real.

Os testes foram validados localmente com Node.js; a execucao completa Jenkins/Docker/SonarQube e os prints dependem do ambiente do aluno.

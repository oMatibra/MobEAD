# Registro de comandos Git — Unidade 2 / Matibra

## Repositorio de referencia

`https://github.com/osanam-giordane/MobEAD`

## Consultas feitas durante a preparacao

```bash
git ls-remote https://github.com/osanam-giordane/MobEAD.git HEAD
git clone --depth 1 https://github.com/osanam-giordane/MobEAD.git mobead-trabalho
git status --short
```

## Comandos que o aluno executara no proprio fork

Primeiro acesse o repositorio original no navegador e clique em **Fork**. Em seguida, no PowerShell ou Git Bash, troque `SEU_USUARIO` pelo nome da sua conta GitHub:

```bash
git --version
git clone https://github.com/SEU_USUARIO/MobEAD.git
cd MobEAD
git remote -v
git branch --show-current
```

**Antes dos proximos comandos**, copie os arquivos deste pacote para dentro da pasta `MobEAD` clonada, incluindo `.dockerignore`, e substitua os arquivos com o mesmo nome. O arquivo original `teste.js` deve ser removido no fork porque tinha sintaxe invalida e foi substituido por `mobead.test.cjs`.

```bash
git status
git add -A
git commit -m "feat: pipeline Jenkins SonarQube com testes e deploy dev prod"
git push -u origin main
git log -1 --oneline
```

Caso o branch principal do seu fork nao seja `main`, substitua `main` pelo resultado de `git branch --show-current`.

## Verificacao no Jenkins

O stage `01 - GitHub / Checkout` executa `checkout scm` e mostra o commit com:

```bash
git log -1 --format="Commit: %h | Autor: %an | Mensagem: %s"
```

## Evidencia a anexar

Depois de executar os comandos, tire um print do terminal mostrando `git remote -v`, `git log -1 --oneline` e `git status` (com as alteracoes ja enviadas), ou copie a saida real para seu relatorio. **Nao confunda comandos preparados com comandos efetivamente executados na sua conta.**

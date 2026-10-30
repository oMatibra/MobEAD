pipeline {
    agent { label 'built-in' }

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    environment {
        PATH = "C:\\Users\\matib\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin;${env.PATH}"
        IMAGE_NAME = 'mobead-matibra'
        DOCKER_NETWORK = 'mobead_cicd'
    }

    stages {
        stage('01 - GitHub / Checkout') {
            steps {
                echo 'Pipeline MATIBRA - CI/CD MobEAD - Windows'
                checkout scm
                bat 'git log -1 --format="Commit: %%h | Autor: %%an | Mensagem: %%s"'
                bat 'docker version'
            }
        }

        stage('02 - Testes automatizados') {
            steps {
                bat '''@echo off
                    docker run --rm --mount "type=bind,source=%CD%,target=/workspace" --workdir /workspace node:22-alpine node --test --test-reporter=tap mobead.test.cjs > tests.tap
                    if errorlevel 1 exit /b 1
                    type tests.tap
                    docker run --rm --mount "type=bind,source=%CD%,target=/workspace" --workdir /workspace node:22-alpine node tap-to-sonar.cjs tests.tap sonar-tests.xml
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('03 - Analise SonarQube') {
            steps {
                withSonarQubeEnv('sonarqube-local') {
                    bat '''@echo off
                        docker run --rm ^
                          --mount "type=bind,source=%CD%,target=/usr/src" ^
                          --workdir /usr/src ^
                          --env "SONAR_TOKEN=%SONAR_AUTH_TOKEN%" ^
                          sonarsource/sonar-scanner-cli ^
                          -Dsonar.host.url=http://host.docker.internal:9000 ^
                          -Dsonar.scanner.metadataFilePath=/usr/src/.scannerwork/report-task.txt
        
                        if errorlevel 1 exit /b 1
                    '''
                }
            }
        }

        stage('04 - Quality Gate') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('05 - Build imagem Docker') {
            steps {
                bat '''@echo off
                    docker build -t "%IMAGE_NAME%:%BUILD_NUMBER%" .
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('06 - Deploy desenvolvimento') {
            steps {
                bat '''@echo off
                    docker network inspect "%DOCKER_NETWORK%" >nul 2>&1
                    if errorlevel 1 docker network create "%DOCKER_NETWORK%"
                    if errorlevel 1 exit /b 1
                    docker container inspect mobead-dev >nul 2>&1
                    if not errorlevel 1 (
                        docker container rm -f mobead-dev
                        if errorlevel 1 exit /b 1
                    )
                    docker run -d --restart unless-stopped --name mobead-dev --network "%DOCKER_NETWORK%" -p 8081:80 "%IMAGE_NAME%:%BUILD_NUMBER%"
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('07 - Smoke test desenvolvimento') {
            steps {
                bat '''@echo off
                    docker run --rm --network "%DOCKER_NETWORK%" curlimages/curl:latest -fsS --retry 12 --retry-all-errors --retry-delay 2 http://mobead-dev/ > smoke-dev.html
                    if errorlevel 1 exit /b 1
                    findstr /C:"MobEAD - UNYLEYA - Engenharia DevOps" smoke-dev.html >nul
                    if errorlevel 1 exit /b 1
                    docker run --rm --network "%DOCKER_NETWORK%" curlimages/curl:latest -fsS --retry 12 --retry-all-errors --retry-delay 2 -o /dev/null http://mobead-dev/Scripts/mobEAD.js
                    if errorlevel 1 exit /b 1
                    echo Smoke test DEV: OK
                '''
            }
        }

        stage('08 - Aprovacao para producao') {
            steps {
                timeout(time: 24, unit: 'HOURS') {
                    input message: 'Testes, SonarQube e DEV aprovados. Liberar deploy em PRODUCAO?',
                          ok: 'Aprovar deploy PRODUCAO'
                }
            }
        }

        stage('09 - Deploy producao') {
            steps {
                bat '''@echo off
                    docker container inspect mobead-prod >nul 2>&1
                    if not errorlevel 1 (
                        docker container rm -f mobead-prod
                        if errorlevel 1 exit /b 1
                    )
                    docker run -d --restart unless-stopped --name mobead-prod --network "%DOCKER_NETWORK%" -p 8082:80 "%IMAGE_NAME%:%BUILD_NUMBER%"
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('10 - Smoke test producao') {
            steps {
                bat '''@echo off
                    docker run --rm --network "%DOCKER_NETWORK%" curlimages/curl:latest -fsS --retry 12 --retry-all-errors --retry-delay 2 http://mobead-prod/ > smoke-prod.html
                    if errorlevel 1 exit /b 1
                    findstr /C:"MobEAD - UNYLEYA - Engenharia DevOps" smoke-prod.html >nul
                    if errorlevel 1 exit /b 1
                    docker run --rm --network "%DOCKER_NETWORK%" curlimages/curl:latest -fsS --retry 12 --retry-all-errors --retry-delay 2 -o /dev/null http://mobead-prod/Scripts/mobEAD.js
                    if errorlevel 1 exit /b 1
                    echo Smoke test PROD: OK
                '''
            }
        }
    }

    post {
        always {
            bat '''@echo off
                if not exist evidencias mkdir evidencias
                echo Pipeline: MATIBRA - CI/CD MobEAD > evidencias/resumo-execucao.txt
                echo Build: %BUILD_NUMBER% >> evidencias/resumo-execucao.txt
                git rev-parse --short HEAD >> evidencias/resumo-execucao.txt 2>nul
                docker ps --filter name=mobead-dev --filter name=mobead-prod --format "{{.Names}} | {{.Image}} | {{.Status}} | {{.Ports}}" >> evidencias/resumo-execucao.txt 2>nul
                docker logs --tail 40 mobead-dev > evidencias/dev-container.log 2>&1
                docker logs --tail 40 mobead-prod > evidencias/prod-container.log 2>&1
                exit /b 0
            '''
            archiveArtifacts artifacts: 'evidencias/*.txt,evidencias/*.log,tests.tap,sonar-tests.xml,smoke-*.html', allowEmptyArchive: true
        }
        success { echo 'PIPELINE MATIBRA: SUCESSO! DEV e PROD disponiveis.' }
        failure { echo 'PIPELINE MATIBRA: FALHA. Consulte Console Output no Jenkins.' }
        aborted { echo 'PIPELINE MATIBRA: CANCELADA (ou aprovacao de PROD recusada).' }
    }
}

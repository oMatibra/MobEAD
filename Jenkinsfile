pipeline {
    agent {
        node {
            label 'built-in'
            // Volume compartilhado somente para os runners de testes e analise.
            customWorkspace '/workspace/mobead'
        }
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    environment {
        PATH = "C:\\Users\\matib\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin;${env.PATH}"
        
        IMAGE_NAME = 'mobead-matibra'
        DOCKER_NETWORK = 'mobead_cicd'
        WORKSPACE_VOLUME = 'mobead_workspace'
    }

    stages {
        stage('01 - GitHub / Checkout') {
            steps {
                echo 'Pipeline MATIBRA - CI/CD MobEAD - Unidade 2'
                checkout scm
                sh 'git log -1 --format="Commit: %h | Autor: %an | Mensagem: %s"'
            }
        }

        stage('02 - Testes automatizados') {
            steps {
                sh '''#!/bin/sh
                    set -eu
                    docker run --rm \
                        --volume "$WORKSPACE_VOLUME:/workspace:ro" \
                        --workdir /workspace/mobead \
                        node:22-alpine node --test --test-reporter=tap mobead.test.cjs > tests.tap
                    cat tests.tap
                    docker run --rm \
                        --volume "$WORKSPACE_VOLUME:/workspace" \
                        --workdir /workspace/mobead \
                        node:22-alpine node tap-to-sonar.cjs tests.tap sonar-tests.xml
                '''
            }
        }

        stage('03 - Analise SonarQube') {
            steps {
                withSonarQubeEnv('sonarqube-local') {
                    sh '''#!/bin/sh
                        set -eu
                        export SONAR_TOKEN="$SONAR_AUTH_TOKEN"
                        docker run --rm \
                            --user 0:0 \
                            --network "$DOCKER_NETWORK" \
                            --volume "$WORKSPACE_VOLUME:/usr/src" \
                            --workdir /usr/src/mobead \
                            --env SONAR_HOST_URL \
                            --env SONAR_TOKEN \
                            sonarsource/sonar-scanner-cli
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
                sh '''#!/bin/sh
                    set -eu
                    docker build -t "$IMAGE_NAME:$BUILD_NUMBER" .
                '''
            }
        }

        stage('06 - Deploy desenvolvimento') {
            steps {
                sh '''#!/bin/sh
                    set -eu
                    docker container rm -f mobead-dev 2>/dev/null || true
                    docker run -d --restart unless-stopped \
                        --name mobead-dev \
                        --network "$DOCKER_NETWORK" \
                        -p 8081:80 \
                        "$IMAGE_NAME:$BUILD_NUMBER"
                '''
            }
        }

        stage('07 - Smoke test desenvolvimento') {
            steps {
                sh '''#!/bin/sh
                    set -eu
                    docker run --rm --network "$DOCKER_NETWORK" \
                        curlimages/curl:latest -fsS --retry 12 --retry-all-errors --retry-delay 2 http://mobead-dev/ \
                        | grep -Fq 'MobEAD - UNYLEYA - Engenharia DevOps'
                    docker run --rm --network "$DOCKER_NETWORK" \
                        curlimages/curl:latest -fsS --retry 12 --retry-all-errors --retry-delay 2 -o /dev/null http://mobead-dev/Scripts/mobEAD.js
                    echo 'Smoke test DEV: OK'
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
                sh '''#!/bin/sh
                    set -eu
                    docker container rm -f mobead-prod 2>/dev/null || true
                    docker run -d --restart unless-stopped \
                        --name mobead-prod \
                        --network "$DOCKER_NETWORK" \
                        -p 8082:80 \
                        "$IMAGE_NAME:$BUILD_NUMBER"
                '''
            }
        }

        stage('10 - Smoke test producao') {
            steps {
                sh '''#!/bin/sh
                    set -eu
                    docker run --rm --network "$DOCKER_NETWORK" \
                        curlimages/curl:latest -fsS --retry 12 --retry-all-errors --retry-delay 2 http://mobead-prod/ \
                        | grep -Fq 'MobEAD - UNYLEYA - Engenharia DevOps'
                    docker run --rm --network "$DOCKER_NETWORK" \
                        curlimages/curl:latest -fsS --retry 12 --retry-all-errors --retry-delay 2 -o /dev/null http://mobead-prod/Scripts/mobEAD.js
                    echo 'Smoke test PROD: OK'
                '''
            }
        }
    }

    post {
        always {
            sh '''#!/bin/sh
                mkdir -p evidencias
                {
                    echo "Pipeline: MATIBRA - CI/CD MobEAD"
                    echo "Build: $BUILD_NUMBER"
                    echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo indisponivel)"
                    echo 'Containers de desenvolvimento e producao:'
                    docker ps --filter name=mobead-dev --filter name=mobead-prod \
                        --format '{{.Names}} | {{.Image}} | {{.Status}} | {{.Ports}}' || true
                } > evidencias/resumo-execucao.txt
                docker logs --tail 40 mobead-dev > evidencias/dev-container.log 2>&1 || true
                docker logs --tail 40 mobead-prod > evidencias/prod-container.log 2>&1 || true
            '''
            archiveArtifacts artifacts: 'evidencias/*.txt,evidencias/*.log,tests.tap,sonar-tests.xml', allowEmptyArchive: true
        }
        success { echo 'PIPELINE MATIBRA: SUCESSO! DEV e PROD disponiveis.' }
        failure { echo 'PIPELINE MATIBRA: FALHA. Consulte Console Output no Jenkins.' }
        aborted { echo 'PIPELINE MATIBRA: CANCELADA (ou aprovacao de PROD recusada).' }
    }
}

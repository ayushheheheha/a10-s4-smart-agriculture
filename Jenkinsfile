pipeline {
    agent any
    // pipeline type 1: parameterized build
    parameters {
        booleanParam(name: 'DEPLOY', defaultValue: true, description: 'Push the image and deploy to Kubernetes')
    }
    triggers { pollSCM('* * * * *') }
    environment {
        PATH = "C:\\Users\\Ayush Yadav\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin;${env.PATH}"
        IMAGE = "ayushsksksk/smart-agriculture"
        VERSION = "1.0.${env.BUILD_NUMBER}"
    }
    stages {
        stage('Clone Code') {
            steps {
                checkout scm
            }
        }
        stage('Build') {
            steps {
                bat """powershell -NoProfile -Command "(Get-Content index.html) -replace '0.0.0-dev','${env.VERSION}' | Set-Content index.html -Encoding UTF8" """
                bat 'docker build -t %IMAGE%:%VERSION% -t %IMAGE%:latest .'
            }
        }
        // pipeline type 2: parallel stages
        stage('Test') {
            parallel {
                stage('Page Checks') {
                    steps {
                        bat 'findstr /C:"Smart Agriculture Dashboard" index.html'
                        bat 'findstr /C:"MOISTURE_LIMIT" index.html'
                    }
                }
                stage('Image Checks') {
                    steps {
                        bat 'docker image inspect %IMAGE%:%VERSION%'
                        bat 'docker run --rm %IMAGE%:%VERSION% nginx -t'
                    }
                }
            }
        }
        // pipeline type 3: archive build artifacts
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'index.html, Dockerfile, deployment.yaml, Jenkinsfile', fingerprint: true
            }
        }
        // pipeline type 4: conditional stage execution (only when DEPLOY is ticked)
        stage('Push Image') {
            when { expression { params.DEPLOY } }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub',
                        usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    bat 'docker login -u %USER% -p %PASS%'
                    bat 'docker push %IMAGE%:%VERSION%'
                    bat 'docker push %IMAGE%:latest'
                }
            }
        }
        stage('Deploy') {
            when { expression { params.DEPLOY } }
            steps {
                withCredentials([file(credentialsId: 'kuberconfig', variable: 'KUBECONFIG')]) {
                    bat """powershell -NoProfile -Command "(Get-Content deployment.yaml -Raw) -replace '__TAG__','${env.VERSION}' | Set-Content rendered.yaml" """
                    bat 'kubectl apply -f rendered.yaml --validate=false'
                }
            }
        }
        stage('Verify and Rollback') {
            when { expression { params.DEPLOY } }
            steps {
                withCredentials([file(credentialsId: 'kuberconfig', variable: 'KUBECONFIG')]) {
                    script {
                        def rc = bat(returnStatus: true, script: 'kubectl rollout status deployment/smart-agriculture --timeout=75s')
                        if (rc != 0) {
                            echo "Release ${env.VERSION} FAILED - rolling back to the previous stable release"
                            bat 'kubectl rollout undo deployment/smart-agriculture'
                            bat 'kubectl rollout status deployment/smart-agriculture --timeout=120s'
                            bat 'kubectl rollout history deployment/smart-agriculture'
                            bat 'kubectl get pods -l app=smart-agriculture'
                            error("Release ${env.VERSION} failed and was rolled back automatically")
                        }
                        bat 'kubectl rollout history deployment/smart-agriculture'
                        bat 'kubectl get pods -l app=smart-agriculture'
                    }
                }
            }
        }
    }
}

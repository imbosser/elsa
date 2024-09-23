pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub')
        GITHUB_CREDENTIALS = credentials('github')
        KUBE_CONFIG = credentials('kubeconfig')
        SONAR_TOKEN = credentials('sonar-token')
    }
    
    stages {
        stage('Checkout') {
            steps {
                dir('app/') {
                    git branch: 'main', credentialsId: 'github', url: 'https://github.com/sahat/hackathon-starter.git'
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                dir('app/') {
                    sh 'npm install'
                    sh 'npm run test'
                }
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                dir('app/') {
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            sonar-scanner \
                            -Dsonar.projectKey=hackathon-starter \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=http://your-sonarqube-url:9000 \
                            -Dsonar.login=$SONAR_TOKEN
                        """
                    }
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                dir('app/') {
                    sh 'docker build -t ${DOCKERHUB_USERNAME}/hackathon-starter-frontend:latest -f Dockerfile.frontend'
                    sh 'docker build -t ${DOCKERHUB_USERNAME}/hackathon-starter-backend:latest -f Dockerfile.backend'
                }
            }
        }
        
        stage('Push Docker Images') {
            steps {
                dir('app/') {
                    sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                    sh 'docker push ${DOCKERHUB_USERNAME}/hackathon-starter-frontend:latest'
                    sh 'docker push ${DOCKERHUB_USERNAME}/hackathon-starter-backend:latest'
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                dir('app/') {
                    sh 'mkdir -p ~/.kube'
                    sh 'echo "$KUBE_CONFIG" > ~/.kube/config'
                    sh 'helm install mongo bitnami/mongodb'
                    sh 'kubectl create configmap app-config --from-env-file=.env.example'
                    sh 'envsubst < setup/deployment/backend/deployment.yaml | kubectl apply -f -'
                    sh 'envsubst < setup/deployment/frontend/deployment.yaml | kubectl apply -f -'
                    sh 'kubectl apply -f setup/deployment/frontend/ingress.yaml'
                    sh 'kubectl apply -f setup/deployment/backend/ingress.yaml'
                    sh 'kubectl apply -f setup/deployment/hpa.yaml'
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
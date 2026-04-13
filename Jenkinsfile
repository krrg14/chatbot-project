pipeline {
    agent any

    environment {
        IMAGE_NAME = "krrg14/chatbot:${GIT_COMMIT}"
    }

    stages {
        stage('check out') {
            steps{
                git branch: 'main', url: 'https://github.com/krrg14/chatbot-project.git'
            }
        }

        stage('docker build'){
            steps{
                sh'''
                    printenv
                    docker build -t ${IMAGE_NAME} .
                '''
            }
        }

        stage('testing'){
            steps{
                sh'''
                    docker kill chatbot
                    docker rm chatbot
                    docker run -it -d --name chatbot -p 9000:8501 ${IMAGE_NAME}
                '''
            }
        }

        stage('docker login'){
            steps{
                withCredentials([usernamePassword(
                    credentialsID:    'docker-hub-cred'
                    usernameVariable: "DOCKER_USERNAME"
                    passwordVariable: "DOCKER_PASSWORD"
                )]) {
                    sh 'echo $DOCKER_PASSWORD  | docker login -u $DOCKER_USERNAME --password-stdin'
                }
            }
        }

        stage('docker push'){
            steps{
                sh 'docker push ${IMAGE_NAME}'
            }
        }
    }
}
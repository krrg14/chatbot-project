pipeline {
    agent any

    environment {
        IMAGE_NAME = "chatbot:${GIT_COMMIT}"
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
                    docker run -it -d --name chatbot -p 9000:8501 ${IMAGE_NAME}
                '''
            }
        }
    }
}
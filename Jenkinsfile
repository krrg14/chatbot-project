pipeline {
    agent any

    environment {
        IMAGE_NAME = "krrg14/chatbot:${GIT_COMMIT}"
        NAMESPACE = "chatbot"
        REGION = "ap-south-1"
        CLUSTER_NAME = "chatbot_cluster"
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
                    docker build -t ${IMAGE_NAME} . 
                '''
            }
        }

        stage('docker login'){
            steps{
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-cred', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                    }
                }
            }
        }


        stage('docker push'){
            steps{
                sh 'docker push ${IMAGE_NAME}'
            }
        }

        stage('update the cluster'){
            steps{
                sh "aws eks update-kubeconfig --region ${REGION} --name ${chatbot_cluster}"
            }
        }

        stage('deploy to EKS cluster') {
            steps {
                withKubeConfig(caCertificate: '', clusterName: 'chatbot_cluster', contextName: '', credentialsId: 'kube', namespace: 'chatbot', restrictKubeConfigAccess: false, serverUrl: 'https://6EC17A81BB656431D6E3B1996451DC32.gr7.ap-south-1.eks.amazonaws.com') {
                    sh "sed 's|replace|${IMAGE_NAME}|g' Deployment.yaml"
                    sh "kubectl apply -f Deployment.yaml -n ${NAMESPACE}"
                }
            }
        }

                stage('verifying the  cluster') {
            steps {
                withKubeConfig(caCertificate: '', clusterName: 'chatbot_cluster', contextName: '', credentialsId: 'kube', namespace: 'chatbot', restrictKubeConfigAccess: false, serverUrl: 'https://6EC17A81BB656431D6E3B1996451DC32.gr7.ap-south-1.eks.amazonaws.com') {
                    sh "kubectl get pods -n ${NAMESPACE}"
                    sh "kubectl get svc -n ${NAMESPACE}"
                }
            }
        }
    }
}
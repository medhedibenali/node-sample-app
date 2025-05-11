pipeline {
    environment {
        registry = 'medhedibenali/node-sample-app'
        registryCredential = 'docker_hub_id'
        dockerImage = ''
    }

    agent any

    stages {
        stage('Clone the repository') {
            steps {
                git url: 'https://github.com/medhedibenali/node-sample-app.git', branch: 'dev'
            }
        }

        stage('Test the app') {
            environment {
                nodeHome = tool 'Node23'
            }

            steps {
                sh '${nodeHome}/bin/node --test'
            }
        }

        stage('Build the image') {
            steps{
                script {
                    dockerImage = docker.build registry + ":$BUILD_NUMBER-dev"
                }
            }
        }

        stage('Push the image') {
            steps{
                script {
                    docker.withRegistry( '', registryCredential ) {
                        dockerImage.push()
                    }
                }
            }
        }

        stage('Update the latest tag') {
            steps{
                script {
                    docker.withRegistry( '', registryCredential ) {
                        dockerImage.push 'latest'
                    }
                }
            }
        }

        stage('Clean up') {
            steps {
                sh 'docker rmi $registry:$BUILD_NUMBER-dev'
            }
        }

        stage('Create the infrastructure') {
            steps {
                sh 'tofu init'
                sh 'tofu plan -var="ssh_key=$(cat $HOME/.ssh/id_ed25519.pub)" -out tfplan'
                sh 'tofu apply tfplan'
            }
        }

        stage('Deploy the application') {
            steps {
                sh 'echo "[webservers]\n$(tofu output -raw vm_ip)" > hosts'
                sh '''
                    ansible-playbook playbook.yml -i hosts \
                        --extra-vars "tag=$BUILD_NUMBER-dev"
                '''
            }
        }
    }
}

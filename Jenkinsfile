pipeline {
    environment {
        registry = 'medhedibenali/node-sample-app'
        registryCredential = 'docker_hub_id'
        dockerImage = ''
        KUBECONFIG = credentials('kubeconfig_id')
    }

    agent any

    stages {
        stage('Clone the repository') {
            steps {
                git url: 'https://github.com/medhedibenali/node-sample-app.git', branch: 'main'
            }
        }

        stage('Test the app') {
            environment {
                nodeHome = tool 'Node23'
            }

            steps {
                sh '''
                    ${nodeHome}/bin/node --test --experimental-test-coverage \
                        --test-reporter=lcov --test-reporter-destination=lcov.info
                '''
            }
        }

        stage('Scan the code') {
            environment {
                scannerHome = tool 'Sonar'
            }

            steps {
                script {
                    withSonarQubeEnv('Default') {
                        sh '${scannerHome}/bin/sonar-scanner'
                    }
                }
            }
        }

        stage('Quality gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                  waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build the image') {
            steps{
                script {
                    dockerImage = docker.build registry + ":$BUILD_NUMBER"
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
                sh 'docker rmi $registry:$BUILD_NUMBER'
            }
        }

        stage('Deploy the app') {
            steps {
                sh 'kubectl apply -f service.yaml'
                sh '''
                    if ! kubectl apply view-last-applied \
                        -f deployment.yaml 1> /dev/null 2>&1; then
                        kubectl apply -f deployment.yaml
                    fi
                '''
                sh '''
                    kubectl set image \
                    deployments node-sample-app-deployment \
                    node-sample-app=$registry:$dockerImage
                '''
            }
        }
    }
}

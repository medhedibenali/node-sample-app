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
                sh '''
                    helm upgrade --install \
                        --set image.tag=$BUILD_NUMBER \
                        node-sample-app ./node-sample-app
                '''
            }
        }
    }
}

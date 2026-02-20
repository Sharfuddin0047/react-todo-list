pipeline {
    agent any

    environment {
        DOCKER_USER = 'sharfuddin47'
        IMAGE_NAME = 'to_do_app'
        BUILD_TAG   = "${env.BUILD_NUMBER}"
        PROD_SERVER = "ec2-54-234-234-0.compute-1.amazonaws.com"
    }

    stages {
        stage('cleanup') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout') {
            steps {
                echo 'This stage copies the source code'
                git url: 'https://github.com/Sharfuddin0047/react-todo-list.git' ,branch: 'master'
            }
        }
        stage('Build and server setup') {
            parallel {
                stage('Build') {
                    steps {
                        echo 'This stage build app'
                        sh '''
                            docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_TAG} .
                        '''
                    }
                }
                stage('Setup-test-server') {
                    environment {
                        TEST_SERVER_DNS = credentials('ec2-test-server-dns')
                    }
                    steps {
                        sshagent(['ssh-test-server']) {
                            sh '''
                    ssh-keyscan -H $TEST_SERVER_DNS >> ~/.ssh/known_hosts
                    scp ./scripts/setup.sh ubuntu@$TEST_SERVER_DNS:/tmp/setup.sh
                    ssh ubuntu@$TEST_SERVER_DNS "bash /tmp/setup.sh"
                '''
                        }
                    }
                }
                stage('Setup-prod-server') {
                    environment {
                        PROD_SERVER_DNS = credentials('ec2-prod-server-dns')
                    }
                    steps {
                        sshagent(['ssh-prod-server']) {
                            sh '''
                    ssh-keyscan -H $PROD_SERVER_DNS >> ~/.ssh/known_hosts
                    scp ./scripts/setup.sh ubuntu@$PROD_SERVER_DNS:/tmp/setup.sh
                    ssh ubuntu@$PROD_SERVER_DNS "bash /tmp/setup.sh"
                '''
                        }
                    }
                }
            }
        }
        stage('Docker Login and Push') {
            steps {
                echo 'This stage push app'
                withCredentials([usernamePassword(credentialsId: 'dockerPAT', usernameVariable: 'DOCKER_USERNAME',
                passwordVariable: 'DOCKER_PASS')]){
                    sh '''
                        echo $DOCKER_PASS | docker login -u$DOCKER_USERNAME --password-stdin
                        echo "docker login successful"
                        docker push ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_TAG}
                        docker tag ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_TAG} ${DOCKER_USER}/${IMAGE_NAME}:latest
                        docker push ${DOCKER_USER}/${IMAGE_NAME}:latest
                    '''
                }
            }
        }
        stage('Deploy on Test Server') {
                    environment {
                        TEST_SERVER_DNS = credentials('ec2-test-server-dns')
                    }
                    steps {
                        sshagent(['ssh-test-server']) {
                            sh '''
                                ssh ubuntu@$TEST_SERVER_DNS "
                                    docker pull ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_TAG}
                                    docker rm -f ${IMAGE_NAME} || echo "No old container"  
                                    docker run -d --name ${IMAGE_NAME} -p 80:80 ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_TAG}

                                "
                            '''
                        }
                    }
                }
        stage('Approval') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: 'Ready to deploy', ok: 'Yes, I am sure to Deploy'
                }
                
            }
        }
        stage('Deploy on Prod Server') {
                    environment {
                        PROD_SERVER_DNS = credentials('ec2-prod-server-dns')
                    }
                    steps {
                        sshagent(['ssh-prod-server']) {
                            sh '''
                                ssh ubuntu@$PROD_SERVER_DNS "
                                    docker pull ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_TAG}
                                    docker rm -f ${IMAGE_NAME} || echo "No old container"  
                                    docker run -d --name ${IMAGE_NAME} -p 80:80 ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_TAG}
                                "
                            '''
                        }
                    }
                }
        stage('Test Frontend App') {
                steps {
                    sh '''
                        for i in {1..5}; do
                            if curl -s --fail http://${PROD_SERVER}/ > /dev/null; then 
                                echo "Frontend app is live"
                                exit 0
                            fi
                            echo "waiting for app to be ready..."
                            sleep 5
                        done
                        echo "frontend app did not start in time"
                        exit 1
                    '''
                }
            }
    }
}

pipeline {
    agent any

    environment {
        DOCKER_USER = 'sharfuddin47'
        IMAGE_NAME = 'todo-app-ecs'
        AWS_DOCKER_REGISTRY = '382934810609.dkr.ecr.us-east-1.amazonaws.com'
        BUILD_TAG   = "${env.BUILD_NUMBER}"
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_ECS_CLUSTER = 'todo-app-cluster-prod'
        AWS_ECS_SERVICE_PROD = 'TodoApp-TaskDefinition-Prod-service'
        AWS_ECS_TD_PROD = 'TodoApp-TaskDefinition-Prod'
        MOCK_API_URL = credentials('mock-api-url')
    }

    stages {
        stage('Code Checkout') {
            steps {
                echo 'this is cloning the code'
                git url: 'https://github.com/Sharfuddin0047/react-todo-list.git', branch: 'master'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t $IMAGE_NAME:$BUILD_TAG --build-arg VITE_MOCKAPI_BASE_URL=$MOCK_API_URL .
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'my-aws',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY',
                    usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        docker tag $IMAGE_NAME:$BUILD_TAG $AWS_DOCKER_REGISTRY/$IMAGE_NAME:$BUILD_TAG
                        aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_DOCKER_REGISTRY
                        docker push $AWS_DOCKER_REGISTRY/$IMAGE_NAME:$BUILD_TAG
                    '''
                    }
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerPAT',
                    usernameVariable: 'DOCKER_USERNAME',
                    passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh '''
                        docker tag ${IMAGE_NAME}:${BUILD_TAG} ${DOCKER_USERNAME}/${IMAGE_NAME}:${BUILD_TAG}
                        echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                        docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${BUILD_TAG}
                        docker tag ${DOCKER_USERNAME}/${IMAGE_NAME}:${BUILD_TAG} ${DOCKER_USERNAME}/${IMAGE_NAME}:latest
                        docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:latest
                    '''
                    }
            }
        }

        stage('Deploy to AWS') {
            agent {
                docker {
                    image 'amazon/aws-cli'
                    reuseNode true
                    args "-u root --entrypoint=''"
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'my-aws',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY',
                    usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        aws --version
                        sed -i "s/#APP_VERSION#/$BUILD_TAG/g" aws/task-definition-prod.json
                        yum install jq -y
                        LATEST_TD_REVISION=$(aws ecs register-task-definition --cli-input-json file://aws/task-definition-prod.json | jq '.taskDefinition.revision')
                        aws ecs update-service --cluster $AWS_ECS_CLUSTER --service $AWS_ECS_SERVICE_PROD --task-definition $AWS_ECS_TD_PROD:$LATEST_TD_REVISION
                        aws ecs wait services-stable --cluster $AWS_ECS_CLUSTER --services $AWS_ECS_SERVICE_PROD
                    '''
                    }
            }
        }
    }
    post {
        cleanup {
            cleanWs() // Use cleanup instead of always for workspace cleanup to preserve logs for notifications and debugging
        }
    }
}

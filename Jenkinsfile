pipeline {
  agent {
    kubernetes {
      inheritFrom 'k8s-agent'
      defaultContainer 'jnlp'
    }
  }

  environment {
    AWS_DEFAULT_REGION = 'il-central-1'
    IMAGE_REPO         = '314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/k8-nginx'
    IMAGE_TAG          = 'latest'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Push Docker Image') {
      steps {
        container('jnlp') {
          withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-imtech'
          ]]) {
            sh '''
              # start Docker daemon in background
              dockerd --host=unix:///var/run/docker.sock & sleep 10

              # login to ECR
              aws ecr get-login-password --region $AWS_DEFAULT_REGION \
                | docker login --username AWS --password-stdin $IMAGE_REPO

              # build & push
              docker build -t $IMAGE_REPO:$IMAGE_TAG .
              docker push $IMAGE_REPO:$IMAGE_TAG
            '''
          }
        }
      }
    }

    stage('Deploy with Helm') {
      steps {
        container('jnlp') {
          sh '''
            helm repo add bitnami https://charts.bitnami.com/bitnami --force-update
            helm upgrade --install my-nginx bitnami/nginx \
              --namespace dor \
              --set image.repository=$IMAGE_REPO \
              --set image.tag=$IMAGE_TAG
          '''
        }
      }
    }
  }
}


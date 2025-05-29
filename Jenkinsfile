pipeline {
  agent {
    kubernetes {
      inheritFrom 'k8s-agent'
      defaultContainer 'jnlp'
    }
  }

  environment {
    AWS_DEFAULT_REGION = 'il-central-1'
    IMAGE_REPO        = '314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/k8-nginx'
    IMAGE_TAG         = 'latest'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Login to ECR') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          container('jnlp') {
            sh '''
              aws ecr get-login-password --region $AWS_DEFAULT_REGION \
                | docker login \
                  --username AWS \
                  --password-stdin $IMAGE_REPO
            '''
          }
        }
      }
    }

    stage('Build & Push Image') {
      steps {
        container('jnlp') {
          sh '''
            docker build -t $IMAGE_REPO:$IMAGE_TAG .
            docker push $IMAGE_REPO:$IMAGE_TAG
          '''
        }
      }
    }

    stage('Helm Deploy') {
      steps {
        container('jnlp') {
          sh '''
            helm repo add bitnami https://charts.bitnami.com/bitnami --force-update
            helm upgrade --install my-nginx bitnami/nginx \
              --namespace dor \
              --create-namespace \
              --set image.repository=$IMAGE_REPO \
              --set image.tag=$IMAGE_TAG
          '''
        }
      }
    }
  }
}


pipeline {
  agent {
    kubernetes {
      inheritFrom 'k8s-agent'
      defaultContainer 'jnlp'
      containers: [
        containerTemplate(
          name: 'jnlp',
          image: 'jenkins/inbound-agent:latest',
          args: '${computer.jnlpmac} ${computer.name}'
        ),
        containerTemplate(
          name: 'docker',
          image: 'docker:dind',
          privileged: true
        ),
        containerTemplate(
          name: 'helm',
          image: 'dtzar/helm-kubectl:3.18.0',
          command: 'sleep',
          args: '999999'
        )
      ]
      volumes: [
        emptyDirVolume(mountPath: '/home/jenkins/agent', name: 'workspace-volume'),
        emptyDirVolume(mountPath: '/var/lib/docker',   name: 'docker-graph-storage')
      ]
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
        container('docker') {
          withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-creds'
          ]]) {
            sh '''
              # install AWS CLI
              apk add --no-cache python3 py3-pip
              pip3 install awscli

              # default ECR login
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
        container('helm') {
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


pipeline {
  agent {
    kubernetes {
      cloud 'imtech-eks'
      namespace 'dor' 
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-agent
spec:
  serviceAccountName: jenkins
  containers:
  - name: dind
    image: docker:20.10-dind
    securityContext:
      privileged: true
    resources:
      requests:
        cpu: "50m"
        memory: "256Mi"
      limits:
        cpu: "250m"
        memory: "512Mi"

  - name: docker
    image: docker:20.10
    command: [cat]
    tty: true
    resources:
      requests:
        cpu: "25m"
        memory: "128Mi"

  - name: aws-cli
    image: amazon/aws-cli:2.11.0
    command: [cat]
    tty: true
    resources:
      requests:
        cpu: "25m"
        memory: "128Mi"

  - name: helm
    image: alpine/helm:3.10.0
    command: [cat]
    tty: true
    resources:
      requests:
        cpu: "25m"
        memory: "128Mi"

  # jnlp can stay at 100m if needed:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    resources:
      requests:
        cpu: "100m"
        memory: "256Mi"
"""
    }
  }

  environment {
    AWS_REGION   = 'il-central-1'
    ECR_REGISTRY = '314525640319.dkr.ecr.il-central-1.amazonaws.com'
    ECR_REPO     = 'dor/helm/myapp'
    IMAGE_TAG    = "${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Authenticate to ECR') {
      steps {
        container('aws-cli') {
          withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'imtech'
          ]]) {
            script {
              env.ECR_PASSWORD = sh(
                script: "aws --region ${AWS_REGION} ecr get-login-password",
                returnStdout: true
              ).trim()
            }
          }
        }
      }
    }

    stage('Build & Push Docker Image') {
      steps {
        container('docker') {
          sh '''
            echo "=> Waiting for Docker daemon..."
            until docker info > /dev/null 2>&1; do
              sleep 1
            done
            echo "=> Docker is up! Logging in and building..."

            echo "${ECR_PASSWORD}" | docker login -u AWS --password-stdin ${ECR_REGISTRY}
            docker build -t ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} .
            docker push ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
          '''
        }
      }
    }

    stage('Deploy with Helm') {
      steps {
        container('helm') {
          sh """
            helm upgrade --install my-nginx ./myapp-chart \
              --namespace default \
              --set image.repository=314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/helm/myapp \
              --set image.tag=${IMAGE_TAG} \
              --set image.pullSecrets[0].name=ecr-creds
          """
       }
      }
    }
  }

  post {
    always {
      cleanWs()
    }
  }
}

pipeline {
  agent {
    kubernetes {
      cloud 'dor-local'
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
    env:
      - name: DOCKER_TLS_CERTDIR
        value: ""
    args:
      - --host=tcp://0.0.0.0:2375
      - --storage-driver=overlay2

  - name: docker
    image: docker:20.10
    command:
      - cat
    tty: true
    env:
      - name: DOCKER_HOST
        value: tcp://localhost:2375

  - name: aws-cli
    image: amazon/aws-cli:2.11.0
    command:
      - cat
    tty: true

  - name: helm
    image: alpine/helm:3.10.0
    command:
      - cat
    tty: true
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
            sh '''
              # point KUBECONFIG under this workspace so it’s never empty
              export KUBECONFIG="$WORKSPACE/.kube/config"
    
              # create parent directory if needed
              mkdir -p "$(dirname "$KUBECONFIG")"
    
              # generate a kubeconfig for your EKS cluster
              aws eks update-kubeconfig \
                --name imtech01 \
                --region "$AWS_REGION" \
                --kubeconfig "$KUBECONFIG"
            '''
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
            export KUBECONFIG=\${KUBECONFIG}
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


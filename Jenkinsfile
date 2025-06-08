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
    KUBECONFIG   = "${env.WORKSPACE}/.kube/config"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Get ECR Password') {
      steps {
        container('aws-cli') {
          withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'imtech'
          ]]) {
            script {
              env.ECR_PASSWORD = sh(
                script: "aws ecr get-login-password --region ${AWS_REGION}",
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
            until docker info > /dev/null 2>&1; do sleep 1; done

            echo "${ECR_PASSWORD}" | docker login -u AWS --password-stdin ${ECR_REGISTRY}
            docker build -t ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} .
            docker push ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
          '''
        }
      }
    }

    stage('Configure Kubeconfig for EKS') {
      steps {
        container('aws-cli') {
          withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'imtech'
          ]]) {
            sh '''
              mkdir -p "$(dirname "$KUBECONFIG")"
              aws eks update-kubeconfig --name imtech01 --region ${AWS_REGION} --kubeconfig "$KUBECONFIG"
            '''
          }
        }
      }
    }

    stage('Deploy with Helm to EKS') {
      steps {
     container('aws-cli') {
          sh '''
            # Install tar & curl in this Alpine-based image
            apk add --no-cache tar curl
    
            # install helm client
            HELM_VER="v3.10.0"
            curl -sL https://get.helm.sh/helm-${HELM_VER}-linux-amd64.tar.gz \
              | tar xz --strip-components=1 linux-amd64/helm -C /usr/local/bin
    
            # verify we have aws, tar, curl, helm
            aws --version
            tar --version
            helm version
    
            # now deploy
            helm upgrade --install my-nginx ./myapp-chart \
              --namespace default \
              --kubeconfig "${KUBECONFIG}" \
              --set image.repository=${ECR_REGISTRY}/${ECR_REPO} \
              --set image.tag=${IMAGE_TAG} \
              --set image.pullSecrets[0].name=ecr-creds \
              --wait --timeout 5m
          '''
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

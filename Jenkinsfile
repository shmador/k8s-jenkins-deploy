// Jenkinsfile

podTemplate(
  label: 'k8s-agent',
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
      name: 'aws',
      image: 'amazon/aws-cli',
      command: 'sleep',
      args: '999999'
    ),
    containerTemplate(
      name: 'helm',
      image: 'dtzar/helm-kubectl:3.18.0',
      command: 'sleep',
      args: '999999'
    )
  ],
  volumes: [
    emptyDirVolume(mountPath: '/home/jenkins/agent', name: 'workspace-volume'),
    emptyDirVolume(mountPath: '/var/lib/docker',   name: 'docker-graph-storage')
  ]
) {
  node('k8s-agent') {
    checkout scm

    stage('Build & Push Docker Image') {
      withCredentials([[
        $class: 'AmazonWebServicesCredentialsBinding',
        credentialsId: 'aws-creds'
      ]]) {
        // Run AWS login in the aws container
        container('aws') {
          sh '''
            aws ecr get-login-password --region il-central-1 \
              | docker login --username AWS --password-stdin 314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/k8-nginx
          '''
        }

        // Build & push in the docker:dind container
        container('docker') {
          sh '''
            docker build -t 314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/k8-nginx:latest .
            docker push 314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/k8-nginx:latest
          '''
        }
      }
    }

    stage('Deploy with Helm') {
      container('helm') {
        sh '''
          helm repo add bitnami https://charts.bitnami.com/bitnami --force-update
          helm upgrade --install my-nginx bitnami/nginx \
            --namespace dor \
            --set image.repository=314525640319.dkr.ecr.il-central-1.amazonaws.com/dor/k8-nginx \
            --set image.tag=latest
        '''
      }
    }
  }
}


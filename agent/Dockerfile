# Dockerfile.agent
FROM jenkins/inbound-agent:latest

USER root

# Install Docker, AWS CLI, Helm deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      docker.io \
      awscli \
      wget \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Helm v3.18.0
RUN wget https://get.helm.sh/helm-v3.18.0-linux-amd64.tar.gz && \
    tar zxvf helm-v3.18.0-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf linux-amd64 helm-v3.18.0-linux-amd64.tar.gz

# Prepare Docker-in-Docker storage
VOLUME /var/lib/docker

USER jenkins


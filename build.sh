#!/bin/bash

# Configuration
DOCKERHUB_USERNAME=${DOCKERHUB_USERNAME:-"trunghoang"}
FRONTEND_IMAGE_NAME="hackathon-starter-frontend"
BACKEND_IMAGE_NAME="hackathon-starter-backend"
VERSION=${VERSION:-"latest"}

# Building frontend image
echo "Building frontend image..."
docker build -t ${DOCKERHUB_USERNAME}/${FRONTEND_IMAGE_NAME}:${VERSION} -f Dockerfile.frontend .

# Building backend image
echo "Building backend image..."
docker build -t ${DOCKERHUB_USERNAME}/${BACKEND_IMAGE_NAME}:${VERSION} -f Dockerfile.backend .

# Logging into Docker Hub
echo "Logging into Docker Hub..."
docker login

# Pushing frontend image
echo "Pushing frontend image to Docker Hub..."
docker push ${DOCKERHUB_USERNAME}/${FRONTEND_IMAGE_NAME}:${VERSION}

# Pushing backend image
echo "Pushing backend image to Docker Hub..."
docker push ${DOCKERHUB_USERNAME}/${BACKEND_IMAGE_NAME}:${VERSION}

echo "Build and push process completed!"
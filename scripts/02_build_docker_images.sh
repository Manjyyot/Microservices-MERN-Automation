#!/bin/bash
set -e

echo "Building Docker images..."

# Build backend services
docker build -t mern-hello-service ./backend/helloService
docker build -t mern-profile-service ./backend/profileService

# Build frontend
docker build -t mern-frontend ./frontend

echo "Docker images built successfully!"

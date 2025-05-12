#!/bin/bash

# Script to set up the complete GKE CloudBuild CI/CD pipeline

set -e

echo "Setting up Google Kubernetes Engine Pipeline using Cloud Build"
echo "=============================================================="

# Setting up variables
echo "Setting up environment variables..."
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
read -p "Enter your preferred region: " REGION
export REGION=$REGION
gcloud config set compute/region $REGION

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Installing now..."
    curl -sS https://webi.sh/gh | sh
    echo "Please restart your shell and run this script again."
    exit 1
fi

# Ensure user is logged in to GitHub
echo "Checking GitHub login..."
if ! gh auth status &> /dev/null; then
    echo "Please login to GitHub:"
    gh auth login
fi

# Setting up GitHub username
export GITHUB_USERNAME=$(gh api user -q ".login")
export USER_EMAIL=$(git config --get user.email)

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable container.googleapis.com \
    cloudbuild.googleapis.com \
    secretmanager.googleapis.com \
    containeranalysis.googleapis.com

# Create Artifact Registry repository
echo "Creating Artifact Registry repository..."
gcloud artifacts repositories create my-repository \
    --repository-format=docker \
    --location=$REGION

# Create GKE cluster
echo "Setting up GKE cluster..."
gcloud container clusters create hello-cloudbuild --num-nodes 1 --region $REGION

# Create GitHub repositories
echo "Creating GitHub repositories..."
gh repo create hello-cloudbuild-app --private --confirm
gh repo create hello-cloudbuild-env --private --confirm

# Setup SSH authentication for GitHub
echo "Setting up SSH authentication for GitHub..."
bash setup_ssh.sh

# Clone repositories
echo "Cloning repositories..."
cd ~
git clone https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-app.git
git clone https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-env.git

# Copy files to app repository
echo "Setting up app repository..."
cd ~/hello-cloudbuild-app
cp -r ~/app.py ~/test_app.py ~/Dockerfile ~/cloudbuild.yaml .
ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github

# Replace placeholder values in app repository files
sed -i "s/\${REGION}/$REGION/g" cloudbuild.yaml
sed -i "s/\${GITHUB_USERNAME}/$GITHUB_USERNAME/g" cloudbuild.yaml
sed -i "s/\${PROJECT_NUMBER}/$PROJECT_NUMBER/g" cloudbuild.yaml

# Initialize app repository
git add .
git commit -m "Initial commit"
git push origin main

# Setup env repository
echo "Setting up env repository..."
cd ~/hello-cloudbuild-env
cp ~/kubernetes.yaml.tpl ~/cloudbuild.yaml .
ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github

# Replace placeholder values in env repository files
sed -i "s/\${REGION}/$REGION/g" cloudbuild.yaml
sed -i "s/\${GITHUB_USERNAME}/$GITHUB_USERNAME/g" cloudbuild.yaml
sed -i "s/\${PROJECT_NUMBER}/$PROJECT_NUMBER/g" cloudbuild.yaml

# Initialize env repository
git add .
git commit -m "Initial commit"
git push origin main

# Create production and candidate branches
git checkout -b production
git push origin production

git checkout -b candidate
git push origin candidate

# Setup Cloud Build triggers
echo "Setting up Cloud Build triggers..."
echo "Please complete the following steps manually in the Google Cloud Console:"
echo "1. Go to Cloud Build > Triggers"
echo "2. Create a trigger for the hello-cloudbuild-app repository"
echo "3. Create a trigger for the hello-cloudbuild-env repository"

echo "For detailed instructions, please refer to the README.md file."

echo "Setup complete! Please follow the remaining manual steps as outlined in the README.md."

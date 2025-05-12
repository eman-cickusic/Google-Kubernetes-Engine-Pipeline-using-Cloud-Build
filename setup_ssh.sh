#!/bin/bash

# Script to set up GitHub SSH authentication for GKE CloudBuild pipeline

# Setting up variables
echo "Setting up environment variables..."
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
export GITHUB_USERNAME=$(gh api user -q ".login")
export USER_EMAIL=$(git config --get user.email)

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

# Create SSH key
echo "Creating SSH key for GitHub..."
mkdir -p ~/workingdir
cd ~/workingdir

if [ -f id_github ]; then
    echo "SSH key already exists. Skipping creation."
else
    ssh-keygen -t rsa -b 4096 -N '' -f id_github -C "$USER_EMAIL"
    echo "SSH key created."
fi

# Create known_hosts file
echo "Creating known_hosts file..."
ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github

echo "===================================================="
echo "MANUAL STEPS REQUIRED:"
echo "===================================================="
echo "1. Upload the private key (id_github) to Secret Manager:"
echo "   - Go to Secret Manager in Google Cloud Console"
echo "   - Create a new secret named 'ssh_key_secret'"
echo "   - Upload the id_github file as the secret value"
echo ""
echo "2. Add the public key to your repository's deploy keys:"
echo "   - Go to your hello-cloudbuild-env repository settings"
echo "   - Navigate to Deploy Keys"
echo "   - Add a new deploy key with title 'SSH_KEY'"
echo "   - Paste the content below:"
echo ""
cat id_github.pub
echo ""
echo "   - Enable 'Allow write access'"
echo ""
echo "3. Grant the service account permission to access Secret Manager:"
echo "   Run the following command:"
echo "   gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \\"
echo "   --member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \\"
echo "   --role=roles/secretmanager.secretAccessor"
echo ""
echo "4. Grant Cloud Build access to GKE:"
echo "   Run the following command:"
echo "   gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \\"
echo "   --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \\"
echo "   --role=roles/container.developer"
echo ""
echo "===================================================="

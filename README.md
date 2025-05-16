# Goolge Kubernetes Engine Pipeline using Cloud Build

This guide walks you through setting up the Cloud Build triggers for both repositories in your CI/CD pipeline.

## App Repository Trigger (CI Pipeline)

1. Go to the Google Cloud Console and navigate to **Cloud Build > Triggers**.
2. Click **Create Trigger**.
3. Fill in the following details:
   - **Name**: `hello-cloudbuild`
   - **Region**: Your preferred region (same as the one used in setup)
   - **Event**: `Push to a branch`
   - **Source**:
     - **Repository**: Select or connect to `${GITHUB_USERNAME}/hello-cloudbuild-app`
     - **Branch**: `.*` (any branch)
   - **Configuration**:
     - **Type**: `Cloud Build configuration file`
     - **Location**: `/cloudbuild.yaml`
   - **Service account**: Select the Compute Engine default service account
4. Click **Create**.

## Env Repository Trigger (CD Pipeline) 

1. Go to the Google Cloud Console and navigate to **Cloud Build > Triggers**.
2. Click **Create Trigger**.
3. Fill in the following details:
   - **Name**: `hello-cloudbuild-deploy`
   - **Region**: Your preferred region (same as the one used in setup)
   - **Event**: `Push to a branch`
   - **Source**:
     - **Repository**: Select or connect to `${GITHUB_USERNAME}/hello-cloudbuild-env`
     - **Branch**: `^candidate$` (only the candidate branch)
   - **Configuration**:
     - **Type**: `Cloud Build configuration file`
     - **Location**: `/cloudbuild.yaml`
   - **Service account**: Select the Compute Engine default service account
4. Click **Create**.

## Testing the Triggers

After setting up the triggers, you can test the complete pipeline:

1. Make a change to your application code in the `hello-cloudbuild-app` repository:
   ```bash
   cd ~/hello-cloudbuild-app
   sed -i 's/Hello World/Hello Cloud Build/g' app.py
   sed -i 's/Hello World/Hello Cloud Build/g' test_app.py
   git add app.py test_app.py
   git commit -m "Hello Cloud Build"
   git push origin main
   ```

2. This will trigger the CI pipeline, which will:
   - Run tests
   - Build a container image
   - Push the image to Artifact Registry
   - Update the Kubernetes manifest in the `hello-cloudbuild-env` repository

3. The update to the `hello-cloudbuild-env` repository will trigger the CD pipeline, which will:
   - Deploy the new version to GKE
   - Update the production branch with the new manifest

4. You can access your application through the LoadBalancer service:
   ```bash
   kubectl get services hello-cloudbuild
   ```

## Rollback Process

To roll back to a previous version of your application:

1. Go to the Cloud Build history for the `hello-cloudbuild-env` repository
2. Find the build corresponding to the version you want to roll back to
3. Click **Rebuild** on that build
4. The CD pipeline will redeploy the older version

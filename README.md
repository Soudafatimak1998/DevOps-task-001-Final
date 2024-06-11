
# DevOps Deployment Pipeline

## Overview

This repository contains scripts and workflows to automate the deployment of an application on AWS using Terraform, Docker, and GitHub Actions. The deployment process includes creating necessary AWS resources, building and pushing Docker images, and running code quality scans with SonarQube.

## Scripts

### driver_script.sh

The `driver_script.sh` script automates the deployment process by performing the following tasks:

1. **Initialization and Configuration: **
   - Sets up environment variables for AWS credentials, region, and resource names.
   - Logs the start of the deployment process.

2. **AWS S3 Bucket Creation: **
   - Creates an S3 bucket for storing deployment artifacts.
   - Logs success or failure of the bucket creation.

3. **AWS DynamoDB Table Creation: **
   - Creates a DynamoDB table to store application data.
   - Logs success or failure of the table creation.

4. **Terraform Initialization and Deployment: **
   - Initializes Terraform for infrastructure as code management.
   - Plans and applies the Terraform configuration to set up AWS resources.
   - Logs success or failure of each Terraform step.

5. **Docker Image Build and Deployment to ECR:**
   - Logs into AWS Elastic Container Registry (ECR).
   - Builds a Docker image of the application.
   - Tags and pushes the Docker image to the ECR repository.
   - Logs success or failure of each Docker step.

6. **SonarQube Scan:**
   - Runs a SonarQube scan to analyze the code for quality and security issues.
   - Logs success or failure of the SonarQube scan.

7. **Completion:**
   - Logs the successful completion of the deployment process.

### deploy_code_github_to_ecr.yml

The `deploy_code_github_to_ecr.yml` GitHub Actions workflow automates the CI/CD pipeline for your project. It includes the following jobs:

1. **Build:**
   - Checks out the code from the repository.
   - Sets up QEMU and Docker Buildx.
   - Logs into Amazon ECR.
   - Builds and pushes the Docker image to ECR.
   - Deploys the application to ECS.

2. **Environment Variables:**
   - Uses GitHub secrets to securely manage sensitive information like AWS credentials and SonarQube tokens.

### ci_cd_pipeline.yml

The `ci_cd_pipeline.yml` GitHub Actions workflow defines a multi-stage CI/CD pipeline. It includes the following stages:

1. **Dev:**
   - Runs on push to the main branch.
   - Checks out the code from the repository.
   - Initializes and applies Terraform configurations.
   - Runs a static code analysis using SonarQube.

2. **QA:**
   - Requires

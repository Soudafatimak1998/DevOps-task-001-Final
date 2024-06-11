#!/bin/bash

# This is the driver script
## This needs to execute First
# All others will be triggered immediately

log() {
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    >&2 echo "[$timestamp] $1"
}

log "Initializing component deployment on AWS"

export AWS_SECRET="awssecret1234"
export AWS_ACCESS_KEY='12345'
export AWS_REGION="us-east-1"
export BUCKET_NAME="devops-deployment"
export TABLE_NAME="devops-20240610"
export ECR_REPOSITORY="devops-deployment-20240610"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ENVIRONMENT="dev"
export SONAR_PROJECT_KEY="SONAR1234"
export SONAR_ORGANIZATION="NONE"
export SONAR_TOKEN="abcd2481ieosnd"

# Connect to the AWS bucket
aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION

if [ "$?" -eq 0 ]; then
  log "Connected to the bucket $BUCKET_NAME"
else
  log "Failed to connect to the bucket! Exiting"
  exit 1
fi

# Create a DynamoDB table
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions \
        AttributeName=Artist,AttributeType=S \
        AttributeName=SongTitle,AttributeType=S \
    --key-schema \
        AttributeName=Artist,KeyType=HASH \
        AttributeName=SongTitle,KeyType=RANGE \
    --provisioned-throughput \
        ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --table-class STANDARD

if [ "$?" -eq 0 ]; then
  log "Created db.table : $TABLE_NAME"
else
  log "Failed to create the Table $TABLE_NAME! Exiting"
  exit 1
fi

# Initialize Terraform
log "Initializing Terraform..."
terraform init

if [ "$?" -ne 0 ]; then
  log "Terraform initialization failed! Exiting"
  exit 1
fi

# Create Terraform Plan for the deployment
log "Planning Terraform deployment..."
terraform plan -var "environment=${ENVIRONMENT}"

if [ "$?" -ne 0 ]; then
  log "Terraform planning failed! Exiting"
  exit 1
fi

# Apply Terraform configuration
log "Applying Terraform configuration..."
terraform apply -auto-approve -var "environment=${ENVIRONMENT}"

if [ "$?" -ne 0 ]; then
  log "Terraform apply failed! Exiting"
  exit 1
fi

# Log in to AWS ECR
log "Logging in to AWS ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

if [ "$?" -ne 0 ]; then
  log "ECR login failed! Exiting"
  exit 1
fi

# Build Docker image
log "Building Docker image..."
docker build -t ${ECR_REPOSITORY}:latest .

if [ "$?" -ne 0 ]; then
  log "Docker build failed! Exiting"
  exit 1
fi

# Tag Docker image
log "Tagging Docker image..."
docker tag ${ECR_REPOSITORY}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest

if [ "$?" -ne 0 ]; then
  log "Docker tagging failed! Exiting"
  exit 1
fi

# Push Docker image to ECR
log "Pushing Docker image to ECR..."
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest

if [ "$?" -ne 0 ]; then
  log "Docker push failed! Exiting"
  exit 1
fi

# Run SonarQube scan
log "Running SonarQube scan..."
docker run \
  -e SONAR_HOST_URL="https://sonarcloud.io" \
  -e SONAR_LOGIN="${SONAR_TOKEN}" \
  -v "${PWD}:/usr/src" \
  sonarsource/sonar-scanner-cli \
  sonar-scanner \
  -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
  -Dsonar.organization=${SONAR_ORGANIZATION} \
  -Dsonar.sources=. \
  -Dsonar.host.url=https://sonarcloud.io \
  -Dsonar.login=${SONAR_TOKEN}

if [ "$?" -eq 0 ]; then
  log "SonarQube scan completed successfully."
else
  log "SonarQube scan failed!"
  exit 1
fi

log "Deployment completed successfully."

#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if environment is provided
if [ -z "$1" ]; then
    log_error "Environment not specified"
    echo "Usage: $0 <environment> [action]"
    echo "Environments: dev, stage, prod"
    echo "Actions: plan, apply, destroy (default: plan)"
    exit 1
fi

ENVIRONMENT=$1
ACTION=${2:-plan}
TERRAFORM_DIR="terraform"
ENV_DIR="$TERRAFORM_DIR/environments/$ENVIRONMENT"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|stage|prod)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: dev, stage, prod"
    exit 1
fi

# Check if environment directory exists
if [ ! -d "$ENV_DIR" ]; then
    log_error "Environment directory not found: $ENV_DIR"
    exit 1
fi

log_info "Deploying to $ENVIRONMENT environment"

# Change to terraform directory
cd $TERRAFORM_DIR

# Initialize Terraform
log_info "Initializing Terraform..."
terraform init -backend-config="prefix=terraform/state/$ENVIRONMENT"

# Select workspace
log_info "Selecting workspace: $ENVIRONMENT"
terraform workspace select $ENVIRONMENT 2>/dev/null || terraform workspace new $ENVIRONMENT

# Execute action
case $ACTION in
    "plan")
        log_info "Running Terraform plan..."
        terraform plan -var-file="environments/$ENVIRONMENT/terraform.tfvars"
        ;;
    "apply")
        log_info "Running Terraform apply..."
        terraform apply -var-file="environments/$ENVIRONMENT/terraform.tfvars" -auto-approve
        ;;
    "destroy")
        log_warn "Running Terraform destroy..."
        terraform destroy -var-file="environments/$ENVIRONMENT/terraform.tfvars" -auto-approve
        ;;
    *)
        log_error "Invalid action: $ACTION"
        echo "Valid actions: plan, apply, destroy"
        exit 1
        ;;
esac

log_info "Deployment completed successfully!"

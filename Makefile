.PHONY: help setup-backend deploy-dev deploy-stage deploy-prod destroy-dev destroy-stage destroy-prod

# Default target
help:
	@echo "Available targets:"
	@echo "  setup-backend    - Setup Terraform backend"
	@echo "  deploy-dev       - Deploy to development"
	@echo "  deploy-stage     - Deploy to staging"
	@echo "  deploy-prod      - Deploy to production"
	@echo "  destroy-dev      - Destroy development environment"
	@echo "  destroy-stage    - Destroy staging environment"
	@echo "  destroy-prod     - Destroy production environment"

setup-backend:
	@echo "Setting up Terraform backend..."
	@chmod +x scripts/setup-backend.sh
	@./scripts/setup-backend.sh

deploy-dev:
	@echo "Deploying to development environment..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh dev apply

deploy-stage:
	@echo "Deploying to staging environment..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh stage apply

deploy-prod:
	@echo "Deploying to production environment..."
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh prod apply

destroy-dev:
	@echo "Destroying development environment..."
	@./scripts/deploy.sh dev destroy

destroy-stage:
	@echo "Destroying staging environment..."
	@./scripts/deploy.sh stage destroy

destroy-prod:
	@echo "Destroying production environment..."
	@./scripts/deploy.sh prod destroy

plan-dev:
	@./scripts/deploy.sh dev plan

plan-stage:
	@./scripts/deploy.sh stage plan

plan-prod:
	@./scripts/deploy.sh prod plan

#!/bin/bash

set -e

PROJECT_ID="your-project-id"
BUCKET_NAME="ecommerce-terraform-state"
REGION="us-central1"

echo "Setting up Terraform backend..."

# Create bucket for Terraform state
echo "Creating GCS bucket: $BUCKET_NAME"
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://$BUCKET_NAME

# Enable versioning
echo "Enabling versioning on bucket"
gsutil versioning set on gs://$BUCKET_NAME

# Set lifecycle policy
cat > lifecycle.json << EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 30,
          "isLive": false
        }
      }
    ]
  }
}
EOF

gsutil lifecycle set lifecycle.json gs://$BUCKET_NAME
rm lifecycle.json

echo "Terraform backend setup completed!"
echo "Bucket: gs://$BUCKET_NAME"

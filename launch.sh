#!/bin/bash
DB_NAME=mydb
DB_USER=hihealth
AWS_REGION=eu-west-1
REMOTE_USER=admin
SSH_PRIVATE_KEY_JSON_KEY=ec2key_vm_private_key
PRIVATE_KEY_FILE="/tmp/private_key.pem"
RDS_SECRET_NAME="password_rds"
SSH_KEY_SECRET_NAME="key_ec2"

export TF_VAR_SSH_PRIVATE_KEY_JSON_KEY=$SSH_PRIVATE_KEY_JSON_KEY
export TF_VAR_AWS_REGION=$AWS_REGION
export TF_VAR_DB_NAME=$DB_NAME
export TF_VAR_DB_USER=$DB_USER
export TF_VAR_RDS_SECRET_NAME=$RDS_SECRET_NAME
export TF_VAR_SSH_KEY_SECRET_NAME=$SSH_KEY_SECRET_NAME


terraform init && terraform apply -auto-approve

PASSWORD_RDS=$(aws secretsmanager get-secret-value --secret-id $RDS_SECRET_NAME --region $AWS_REGION --query SecretString --output text)

SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id $SSH_KEY_SECRET_NAME --region $AWS_REGION --query SecretString --output text)
SSH_PRIVATE_KEY=$(echo $SECRET_VALUE | jq -r .$SSH_PRIVATE_KEY_JSON_KEY)
echo "$SSH_PRIVATE_KEY" > $PRIVATE_KEY_FILE
chmod 400 $PRIVATE_KEY_FILE
# Execute Terraform and capture outputs


# Extract specific outputs
TF_OUTPUTS=$(terraform output -json)
BACKEND_PRIVATE_IP=$(echo "$TF_OUTPUTS" | jq -r .backend_private_ip.value)
FRONTEND_PUBLIC_DNS=$(echo "$TF_OUTPUTS" | jq -r .frontend_public_dns.value)
RDS_ENDPOINT=$(echo "$TF_OUTPUTS" | jq -r .rds_endpoint.value)
RDS_ENDPOINT=$(echo "$RDS_ENDPOINT" | sed 's/.....$//')


# Commands to execute on the remote host
REMOTE_COMMANDS="
  psql \"host=$RDS_ENDPOINT dbname=$DB_NAME user=$DB_USER password=PASSWORD_RDS\" -c \"GRANT rds_iam TO $DB_USER;\"
"

# Execute commands on the remote host
echo "ssh -i $PRIVATE_KEY_FILE $REMOTE_USER@$FRONTEND_PUBLIC_DNS "$REMOTE_COMMANDS""
ssh -i $PRIVATE_KEY_FILE $REMOTE_USER@$FRONTEND_PUBLIC_DNS "$REMOTE_COMMANDS"

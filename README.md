# Serverless Rails Demo

Demo app for https://serverless-rails.com

### Requirements

- Ruby 3.0.1
- Node LTS
- anycable-go
- Redis

### Usage

```
git clone git@github.com:serverless-rails/serverless-rails-demo.git sr-demo && cd $_
bundle && yarn
cp .env.development.local.sample .env.development.local
cp .env.test.local.sample .env.test.local
```

#### Secrets

The following secrets must be added to AWS SSM:

```
cd tf
aws ssm put-parameter --region $(terraform output -json | jq -r .aws_region.value) --profile serverless-rails-demo --type SecureString --name "/production/SECRET_KEY_BASE" --value "$(../bin/rails secret)"
aws ssm put-parameter --region $(terraform output -json | jq -r .aws_region.value) --profile serverless-rails-demo --type SecureString --name "/production/DATABASE_URL" --value "postgresql://app:$(terraform output -json | jq -r .database_password.value)@$(terraform output -json | jq -r .database_host.value):5432/app"
aws ssm put-parameter --region $(terraform output -json | jq -r .aws_region.value) --profile serverless-rails-demo --type SecureString --name "/production/REDIS_URL" --value "redis://$(terraform output -json | jq -r .redis_host.value)"
aws ssm put-parameter --region $(terraform output -json | jq -r .aws_region.value) --profile serverless-rails-demo --type SecureString --name "/production/SENDGRID_API_KEY" --value "THE-SENDGRID-API-KEY"
aws ssm put-parameter --region $(terraform output -json | jq -r .aws_region.value) --profile serverless-rails-demo --type SecureString --name "/production/AWS_ACCESS_KEY_ID" --value "$(aws configure --profile serverless-rails-demo get aws_access_key_id)"
aws ssm put-parameter --region $(terraform output -json | jq -r .aws_region.value) --profile serverless-rails-demo --type SecureString --name "/production/AWS_SECRET_ACCESS_KEY" --value "$(aws configure --profile serverless-rails-demo get aws_secret_access_key)"
```

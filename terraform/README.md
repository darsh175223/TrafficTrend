# TrafficTrend - Terraform Infrastructure

This directory contains the Terraform Infrastructure as Code (IaC) for deploying the TrafficTrend application to AWS.

## 📁 File Structure

```
terraform/
├── main.tf                  # Provider configuration & backend
├── variables.tf             # Input variables
├── vpc.tf                   # VPC, subnets, NAT gateways
├── security-groups.tf       # Security groups for ALB, ECS, RDS
├── rds.tf                   # SQL Server database
├── ecr.tf                   # Container registries
├── ecs.tf                   # ECS cluster, tasks, services
├── alb.tf                   # Application Load Balancer
├── s3-frontend.tf           # S3 + CloudFront for Angular
├── outputs.tf               # Output values
└── terraform.tfvars.example # Example variables file
```

## 🏗 Architecture

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                        AWS Cloud                         │
                    │  ┌───────────────────────────────────────────────────┐  │
                    │  │                   CloudFront                      │  │
                    │  │                   (Angular)                       │  │
                    │  └───────────────────────────────────────────────────┘  │
                    │                           │                              │
                    │  ┌───────────────────────────────────────────────────┐  │
                    │  │              Application Load Balancer            │  │
                    │  └───────────────────────────────────────────────────┘  │
                    │           │                │               │             │
                    │  ┌────────┴───┐  ┌────────┴───┐  ┌────────┴───┐        │
                    │  │   .NET     │  │   Spring   │  │   Python   │        │  
                    │  │  Backend   │  │   Boot     │  │  AI/ML     │        │
                    │  │  (ECS)     │  │  (ECS)     │  │  (ECS)     │        │
                    │  └──────┬─────┘  └──────┬─────┘  └────────────┘        │
                    │         │               │                               │
                    │  ┌──────┴───────────────┴────────────────────────┐     │
                    │  │              RDS SQL Server                    │     │
                    │  └───────────────────────────────────────────────┘     │
                    └─────────────────────────────────────────────────────────┘
```

## 🚀 Getting Started

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Docker** for building container images

### Deployment Steps

1. **Initialize Terraform**
   ```bash
   cd terraform
   terraform init
   ```

2. **Create your tfvars file**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Review the plan**
   ```bash
   terraform plan
   ```

4. **Apply the infrastructure**
   ```bash
   terraform apply
   ```

5. **Build and push Docker images**
   ```bash
   # Login to ECR
   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com
   
   # Build and push each service
   ```

6. **Deploy Angular frontend**
   ```bash
   cd angular-frontend
   ng build --configuration production
   aws s3 sync dist/angular-frontend/ s3://<bucket-name>/ --delete
   ```

## 💰 Cost Estimation

| Resource | Dev Environment | Prod Environment |
|----------|-----------------|------------------|
| ECS Fargate | ~$50/month | ~$150/month |
| RDS SQL Server | ~$25/month | ~$100/month |
| NAT Gateway | ~$35/month | ~$70/month |
| ALB | ~$20/month | ~$20/month |
| CloudFront | ~$5/month | ~$20/month |
| **Total** | **~$135/month** | **~$360/month** |

## 🔐 Security Notes

- All secrets are stored in AWS SSM Parameter Store
- RDS is deployed in private subnets
- ECS tasks run in private subnets with NAT for outbound
- CloudFront uses HTTPS by default
- Security groups follow least-privilege principle

## 🧹 Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Warning:** This will delete all data including the database!

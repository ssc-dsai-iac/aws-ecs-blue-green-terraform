# AWS ECS Blue-Green Terraform

![image](docs/AWS-ECS-Blue-Green.jpeg?raw=true)


The overall flow for this module is:

* Create an S3 bucket to store Terraform state (To do manually before hand)
* Create a Blue-Green ECS infrastucture in a modular manner
* Deploy the infrastructure incrementally

## Dependencies

* [Terraform](https://www.terraform.io/downloads.html)

## Workflow

1. Create terraform.tfvars based on example template provider.

2. Ensure you have exported the `aws_access_key_id`, `aws_secret_access_key`, and `aws_session_token` so that Terraform can apply changes.

```sh
export aws_access_key_id=<secret>
export aws_secret_access_key=<secret>
export aws_session_token=<secret>
```

> Note: You can store the secrets into .aws/credentials instead of exporting.


3. Initialize and set the Terraform backend configuration parameters for the AWS provider.

```sh
terraform init
```

> Note: You will have to specify your own storage account name for where to store the Terraform state.

4. Create an execution plan and save the generated plan to a file.

```sh
terraform plan -out plan
```

5. Apply the changes.

```sh
terraform apply
```
# TODO:
Backend:
- Finish ECS task definiton
- IAM Policies & Security groups
- Logging All to CloudWatch
- ACM - Cert

Frontend:
- S3 frontend buckets
- Cloudfront
- WAF
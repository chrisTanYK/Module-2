Deploying a New Version of the Package Bundle

Overview

This document provides the necessary CLI commands to create a new version of the package bundle and deploy it using AWS services.

Prerequisites

Before running the commands, ensure you have the following:

AWS CLI installed and configured with the appropriate permissions.

Terraform CLI installed for infrastructure provisioning.

Zip utility installed for packaging files.

Required application files in the correct directory.

Steps to Create a New Version

1️⃣ Build and Package the Application

If your application requires a build step, execute:

npm run build  # For Node.js applications
mvn package    # For Java applications

2️⃣ Create a ZIP Archive of the Application

zip -r package_bundle.zip . -x "*.git*" "*node_modules*" "*terraform*"

3️⃣ Upload Package to S3 (Optional, if using Lambda or ECS)

aws s3 cp package_bundle.zip s3://your-bucket-name/path/to/package_bundle.zip

4️⃣ Deploy New Version using Terraform

Ensure Terraform is initialized:

terraform init

Apply the changes to update resources:

terraform apply -auto-approve

5️⃣ Verify Deployment

Check AWS services to confirm deployment:

aws ecs list-task-definitions    # For ECS deployments
aws lambda list-versions-by-function --function-name myLambdaFunction  # For Lambda
aws deploy list-deployments  # For CodeDeploy

6️⃣ Cleanup Old Versions (If Needed)

aws s3 rm s3://your-bucket-name/path/to/old_package_bundle.zip

Notes

Modify the AWS CLI commands based on your specific AWS service (ECS, Lambda, CodeDeploy, etc.).

Ensure your IAM role has the necessary permissions to execute the commands.

If using Terraform, update your main.tf file accordingly before running terraform apply.

Troubleshooting

If Terraform fails, check logs using:

terraform plan
terraform state list

For AWS service logs, use CloudWatch:

aws logs describe-log-groups
aws logs tail /aws/lambda/myLambdaFunction --follow

Conclusion

This guide provides all the essential steps to bundle, upload, and deploy a new version of your package using CLI commands. Modify these commands based on your specific project needs.


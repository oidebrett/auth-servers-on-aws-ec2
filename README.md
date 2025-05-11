# Authentication Server CloudFormation Templates

This repository contains AWS CloudFormation templates for quickly deploying temporary authentication servers using different authentication platforms.

## Available Templates

- **vps_ec2_base_docker.yaml**: Base template with Docker installed
- **vps_ec2_authentik.yaml**: Authentik authentication server
- **vps_ec2_authelia.yaml**: Authelia authentication server

## Purpose

These templates are designed to help you quickly deploy authentication servers for testing, development, or temporary production use. Each template creates a complete VPC environment with public and private subnets, security groups, and an EC2 instance configured with the selected authentication platform.

## Security Considerations

⚠️ **IMPORTANT**: These templates are provided as starting points and include default configurations that should be modified before use in production:

1. **Change default credentials**: The templates include default users and passwords that should be changed immediately after deployment.
2. **Review security groups**: The security groups allow specific ports from all IPs (0.0.0.0/0) for HTTP/HTTPS access. Restrict these as needed.
3. **Restrict SSH access**: By default, SSH access (port 22) is open to all IPs (0.0.0.0/0). This should be restricted to your specific IP address using the format `your-ip-address/32`.
4. **Update domain names**: Replace the example domain names with your own domains.
5. **SSL certificates**: The templates set up SSL certificates automatically, but you should verify the configuration.

## Usage

1. Log in to the AWS Management Console
2. Navigate to CloudFormation
3. Click "Create stack" > "With new resources (standard)"
4. Upload the desired template file
5. Follow the prompts to configure and deploy the stack
6. Once deployment is complete, check the Outputs tab for access information

## Post-Deployment Steps

After deploying any of these templates:

1. Create DNS records pointing to your EC2 instance (see stack outputs for details)
2. Wait for DNS propagation
3. Access your authentication server using the provided URL
4. Change default credentials immediately
5. Configure additional settings as needed for your use case

## Future Additions

More authentication server templates will be added in the future. Contributions are welcome!

## License

[Add your license information here]

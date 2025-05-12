# Authentication Server CloudFormation Templates

This repository contains AWS CloudFormation templates for quickly deploying temporary authentication servers using different authentication platforms.

## Available Templates

- **vps_ec2_base_docker.yaml**: Base template with Docker installed
- **vps_ec2_authentik.yaml**: Authentik authentication server
- **vps_ec2_authelia.yaml**: Authelia authentication server
- **vps_ec2_pocketid.yaml**: PocketID authentication server

## Purpose

These templates are designed to help you quickly deploy authentication servers for testing, development, or temporary production use. Each template creates a complete VPC environment with public and private subnets, security groups, and an EC2 instance configured with the selected authentication platform.

## Customizing Templates

Before deployment, you can customize the templates using the provided shell script:

```bash
# Make the script executable
chmod +x customize_templates.sh

# Run the customization script
./customize_templates.sh
```

The script will:
1. Prompt you for:
   - Your domain name
   - Authentication subdomain
   - Email address for Let's Encrypt certificates
   - Your IP address for SSH access restrictions
2. Create an `output` directory
3. Generate customized versions of all templates in the `output` directory
4. Leave the original templates unchanged

This ensures your templates are configured with your specific settings before deployment while preserving the original templates.

## Security Considerations

⚠️ **IMPORTANT**: These templates are provided as starting points and include default configurations that should be modified before use in production:

1. **Change default credentials**: The templates include default users and passwords that should be changed immediately after deployment.
2. **Review security groups**: The security groups allow specific ports from all IPs (0.0.0.0/0) for HTTP/HTTPS access. Restrict these as needed.
3. **Restrict SSH access**: By default, SSH access (port 22) is open to all IPs (0.0.0.0/0). Use the customization script to restrict this to your specific IP address.
4. **Update domain names**: Use the customization script to replace the example domain names with your own domains.
5. **SSL certificates**: The templates set up SSL certificates automatically, but you should verify the configuration.

## Usage

1. Run the customization script to configure templates for your environment
2. Log in to the AWS Management Console
3. Navigate to CloudFormation
4. Click "Create stack" > "With new resources (standard)"
5. Upload the desired template file from the `output` directory
6. Follow the prompts to configure and deploy the stack
7. Once deployment is complete, check the Outputs tab for access information

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

See license [here](LICENSE)

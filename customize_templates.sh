#!/bin/bash

echo "CloudFormation Template Customizer"
echo "=================================="

# Function to validate domain
validate_domain() {
    if [[ $1 =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate subdomain
validate_subdomain() {
    if [[ $1 =~ ^[a-zA-Z0-9][-a-zA-Z0-9]*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate email
validate_email() {
    if [[ $1 =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate IP address
validate_ip() {
    if [[ $1 == "0.0.0.0/0" ]]; then
        return 0
    elif [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
        # Basic format check passed, now validate each octet
        IFS='.' read -r -a octets <<< "${1%/*}"
        for octet in "${octets[@]}"; do
            if [[ $octet -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Get domain name
while true; do
    read -p "Enter your domain name (e.g., example.com): " domain
    if validate_domain "$domain"; then
        break
    else
        echo "Invalid domain. Please enter a valid domain name."
    fi
done

# Get authentication subdomain
while true; do
    read -p "Enter authentication subdomain (e.g., auth): " auth_subdomain
    if validate_subdomain "$auth_subdomain"; then
        break
    else
        echo "Invalid subdomain. Use only letters, numbers, and hyphens (must start with letter/number)."
    fi
done

# Get email for Let's Encrypt
while true; do
    read -p "Enter email for Let's Encrypt certificates: " email
    if validate_email "$email"; then
        break
    else
        echo "Invalid email address. Please enter a valid email."
    fi
done

# Get IP address for SSH access
while true; do
    read -p "Enter your IP address for SSH access (or 0.0.0.0/0 for any IP): " ip_address
    if validate_ip "$ip_address"; then
        break
    else
        echo "Invalid IP address format."
    fi
done

# Add CIDR notation if it's a single IP
if [[ "$ip_address" != "0.0.0.0/0" && ! "$ip_address" =~ / ]]; then
    ip_address="${ip_address}/32"
fi

# Create output directory
output_dir="output"
mkdir -p "$output_dir"
echo "Created output directory: $output_dir"

# Process each template
template_dir="cloudformation"

# Find all YAML files in the cloudformation directory
templates=()
for file in "$template_dir"/*.{yaml,yml}; do
    if [ -f "$file" ]; then
        templates+=("$(basename "$file")")
    fi
done

if [ ${#templates[@]} -eq 0 ]; then
    echo "No YAML files found in $template_dir directory."
    exit 1
fi

echo "Found ${#templates[@]} template files to process."

# Add debug function to check original templates
check_original_templates() {
    echo ""
    echo "Checking original templates for patterns to replace:"
    for template in "${templates[@]}"; do
        template_path="${template_dir}/${template}"
        echo "Checking $template for auth.yourdomain.com:"
        grep -c "auth\.yourdomain\.com" "$template_path" || echo "No matches found"
        
        echo "Checking $template for yourdomain.com:"
        grep -c "yourdomain\.com" "$template_path" || echo "No matches found"
    done
}

for template in "${templates[@]}"; do
    template_path="${template_dir}/${template}"
    output_path="${output_dir}/${template}"
    echo "Processing $template_path..."
    
    # Add debug output to see what we're replacing
    echo "Replacing auth.yourdomain.com with $auth_subdomain.$domain"
    
    # Replace domain names and save to output directory
    sed -e "s|CidrIp: 0\.0\.0\.0/0  # For SSH access|CidrIp: $ip_address  # For SSH access|g" \
        -e "s|CidrIp: 0\.0\.0\.0/0  # For SSH access (restrict this to your IP)|CidrIp: $ip_address  # For SSH access (restrict this to your IP)|g" \
        -e "s/auth\.yourdomain\.com/$auth_subdomain.$domain/g" \
        -e "s/authelia\.yourdomain\.com/$auth_subdomain.$domain/g" \
        -e "s/authentik\.yourdomain\.com/$auth_subdomain.$domain/g" \
        -e "s/pocketid\.yourdomain\.com/$auth_subdomain.$domain/g" \
        -e "s/auth\.mydomain\.com/$auth_subdomain.$domain/g" \
        -e "s/authelia\.mydomain\.com/$auth_subdomain.$domain/g" \
        -e "s/authentik\.mydomain\.com/$auth_subdomain.$domain/g" \
        -e "s/pocketid\.mydomain\.com/$auth_subdomain.$domain/g" \
        -e "s/youremail@mail\.com/$email/g" \
        -e "s/admin@yourdomain\.com/$email/g" \
        -e "s/yourdomain\.com/$domain/g" \
        -e "s/mydomain\.com/$domain/g" \
        "$template_path" > "$output_path"
        
    echo "Created customized template: $output_path"
done

echo ""
echo "All templates have been customized successfully!"
echo "Customized templates are available in the '$output_dir' directory."
echo "Authentication server will be accessible at: $auth_subdomain.$domain"
echo "Remember to update your DNS records after deployment."


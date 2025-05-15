# ⚙️ Using AWS CloudFormation to Create Test Authentication Servers for Pangolin and the Middleware Manager

This guide walks you through using AWS CloudFormation to create test-ready authentication servers like **Authelia**, **Authentik**, and **PocketID** to integrate with [Pangolin's Middleware Manager](https://forum.hhf.technology/t/enhancing-your-pangolin-deployment-with-middleware-manager/1324). These preconfigured stacks make it easy to stand up external auth services for testing. Please note, these are purely for testing!!

---

## ✨ New: CloudFormation Template Customizer Script

To simplify the process, a shell script is included that automatically customizes CloudFormation templates with your domain, email, subdomain, and SSH IP restrictions. No manual editing of templates needed!

> ✅ **Output:** Customized CloudFormation templates are stored in an `output/` folder, ready to deploy via the AWS Console.

---

## 📁 Available Authentication Stacks

- **Authelia** – `vps_ec2_authelia.yaml`
- **Authentik** – `vps_ec2_authentik.yaml`
- **PocketID** – `vps_ec2_pocketid.yaml`
- **Zitadel** – `vps_ec2_zitadel.yaml`
- **Base Docker VPS (no auth stack)** – `vps_ec2_base_docker.yaml`

---

## 🧰 Step 1: Run the Customization Script

From your project root, run:

```bash
chmod +x ./customize_templates.sh
./customize_templates.sh
````

You’ll be prompted to enter:

* ✅ Your domain name (e.g., `mydomain.com`)
* ✅ Subdomain for the auth service (e.g., `auth`)
* ✅ Email for Let’s Encrypt (for SSL)
* ✅ Your IP (or CIDR) for SSH access

Example:

```text
Enter your domain name (e.g., example.com): yourdomain.com
Enter authentication subdomain (e.g., auth): auth
Enter email for Let's Encrypt certificates: admin@yourdomain.com
Enter your IP address for SSH access (or 0.0.0.0/0 for any IP): 0.0.0.0/0
```

> ⚠️ If your IP is a single address, the script automatically adds `/32` CIDR notation.

---

## 📦 Step 2: Launch the CloudFormation Stack

1. Go to [CloudFormation Console](https://console.aws.amazon.com/cloudformation/home)
2. Click **"Create stack" > "With new resources (standard)"**
3. Choose **Upload a template file**, and select one of the files in the `output/` directory
4. Name your stack (e.g., `AuthServerStack`)
5. Click through the steps and deploy

---

## 🌐 Step 3: Configure DNS for Your Subdomain

After deployment:

1. Go to [EC2 Console](https://console.aws.amazon.com/ec2)
2. Find your new instance and note the **Public DNS name**
3. In your DNS provider (e.g., Cloudflare):

   * Create a **CNAME** record pointing your subdomain (e.g., `auth.mydomain.com`) to the EC2 DNS
   * **Cloudflare users:** set SSL/TLS mode to **Full**

> 🔁 Example DNS entry:

```
auth.mydomain.com → ec2-XX-XX-XX-XX.region.compute.amazonaws.com
```

---

## 🔐 Step 4: SSH Into Your VPS

Use your previously created or selected EC2 key pair:

```bash
ssh -i "VPS.pem" ubuntu@<your-ec2-public-dns>
```

Check logs to verify the setup:

```bash
cat /var/log/user-data.log
```

Wait about 2 minutes for the server to initialize and the installation to complete. 
Note, Authentik will take longer to initialize.

Manually bring up containers:

```bash
cd ~
sudo docker compose up -d
```

---

## 🛠 Step 5: Attach Middleware in Pangolin

1. Open the **Pangolin Middleware Manager**

2. Go to the **Middlewares** tab

3. Ensure `authelia`, `authentik`, or `pocketid` middleware is listed and configured correctly:

   ```yaml
   - id: authelia
     name: Authelia
     type: forwardAuth
     config:
       address: https://auth.mydomain.com/api/verify
   ```

4. Go to **Dashboard → Manage** on a resource

5. Click **Add Middleware**, choose your auth provider, and save

---

## 🧪 Step 6: Test Access

Open a browser and navigate to your protected Pangolin resource:

```
https://yourapp.mydomain.com
```

You should be redirected to your auth service (Authelia, Authentik, or PocketID), and after logging in, returned to your app.

### Using Authentik for the first time

To start the initial setup, navigate to https://yourapp.mydomain.com/if/flow/initial-setup/


### Using PocketID for the first time
To initiate Pocket ID setup, navigate to https://yourapp.mydomain.com/login/setup

---

## 🔄 Step 8: Integrate with Middleware Manager

1. Open the Pangolin Middleware Manager
2. Go to **Middlewares** tab
3. Ensure your `Authelia` or `Authentik` middleware is listed and correctly configured

   * Example for Authelia:

     ```json
      {
      "address": "https://authelia.yourdomain.com/api/verify?rd=https://authelia.yourdomain.com",
      "authResponseHeaders": [
         "Remote-User",
         "Remote-Groups",
         "Remote-Name",
         "Remote-Email"
      ],
      "trustForwardHeader": true
      }
     ```

   * Example for Authentik:

     ```json
      {
      "address": "http://authentik-proxy:9000/outpost.goauthentik.io/auth/traefik",
      "authResponseHeaders": [
         "X-authentik-username",
         "X-authentik-groups",
         "X-authentik-email",
         "X-authentik-name",
         "X-authentik-uid"
      ],
      "trustForwardHeader": true
      }
     ```

4. Go to **Dashboard > Manage** on the resource you want to protect
5. Click **Add Middleware**
6. Select your new external middleware (e.g., Authelia or Authentik)
7. Save and test

> 📸 Screenshot suggestion: Show attaching the middleware in the Middleware Manager UI.

### 🔐 Special Setup for Authentik on a Separate Host

Since you've deployed Authentik on a separate host from your application servers, you'll need to set up an Authentik Outpost:

1. **Create a new Outpost in Authentik**:
   - Go to your Authentik admin interface
   - Navigate to **Outposts** and create a new Proxy Outpost
   - Click **View** on the new outpost and copy the token

2. **Add the Authentik Proxy to your application server's docker-compose.yml**:

   ```yaml
   authentik-proxy:
     image: ghcr.io/goauthentik/proxy
     container_name: authentik-proxy
     ports:
       - 9000:9000
       - 9443:9443
     environment:
       AUTHENTIK_HOST: https://authentik.yourdomain.com
       AUTHENTIK_INSECURE: "false"
       AUTHENTIK_TOKEN: REPLACE_WITH_YOUR_TOKEN
       # Optional: Set this if your internal communication URL differs from the public URL
       # AUTHENTIK_HOST_BROWSER: https://external-domain.tld
     labels:
       traefik.enable: true
       traefik.port: 9000
       traefik.http.routers.authentik.rule: Host(`authentik.yourdomain.com`) && PathPrefix(`/outpost.goauthentik.io/`)
       traefik.http.middlewares.authentik.forwardauth.address: http://authentik-proxy:9000/outpost.goauthentik.io/auth/traefik
       traefik.http.middlewares.authentik.forwardauth.trustForwardHeader: true
       traefik.http.middlewares.authentik.forwardauth.authResponseHeaders: X-authentik-username,X-authentik-groups,X-authentik-entitlements,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version
   ```

3. **Start the Authentik Proxy**:
   ```bash
   docker compose up -d authentik-proxy
   ```

4. **Configure your middleware in Pangolin** to use the local proxy:
   ```yaml
   - id: authentik
     name: Authentik
     type: forwardAuth
     config:
       address: http://authentik-proxy:9000/outpost.goauthentik.io/auth/traefik
   ```

This setup allows your application server to communicate with your external Authentik instance through the local proxy.

---

## 📌 Summary

With just a few inputs and one command, the CloudFormation Template Customizer sets up ready-to-deploy authentication servers tailored to your environment. It’s perfect for securely testing external authentication flows with Pangolin and its Middleware Manager.

---

## 📌 Final Important Note:

You should go into AWS Cloudformation and **delete** your stack otherwise you will incur costs.

---

Troubleshooting

### If you get an error like this after running pocketid
```
traefik   | 2025-05-12T10:55:46Z ERR Unable to obtain ACME certificate for domains error="unable to generate a certificate for the domains [auth.yourdomain]: error: one or more domains had a problem:\n[auth.yourdomain] invalid authorization: acme: error: 403 :: urn:ietf:params:acme:error:unauthorized :: XX.XX.XX.XX: Invalid response from http://auth.yourdomain.com/.well-known/acme-challenge/kFm8QW5WJbhFTNw1preCE5DXNXZWNxgaEmeUCadYkB8: 404\n" ACME CA=https://acme-v02.api.letsencrypt.org/directory acmeCA=https://acme-v02.api.letsencrypt.org/directory domains=["auth.yourdomain.com"] providerName=myresolver.acme routerName=pocketid@docker rule=Host(`auth.yourdomain.com`)
```
its because letsencrpyt is sending a challenge to the subdomain. You will need to set up your DNS for the subdomain and try again.


### If you get errors creating letencrypt certificates using certbot
```
An unexpected error occurred:
too many certificates (5) already issued for this exact set of domains in the last 168h0m0s, retry after 2025-05-13 21:05:08 UTC: see https://letsencrypt.org/docs/rate-limits/#new-certificates-per-exact-set-of-hostnames
```

its because you have hit the letsencrypt rate limit. You can either wait or use a different domain. Or you can try the --staging flag in the certbot command.

```
The Certificate Authority failed to download the challenge files from the temporary standalone webserver started by Certbot on port 80. Ensure that the listed domains point to this machine and that it can accept inbound connections from the internet.

Some challenges have failed.
```

This is because letsencrypt cant reach your server. You may need to open port 80 in your security group AND make sure that you have set up your DNS correctly.

## 🙏 Thanks for Reading

If you're experimenting with new auth providers or building out secure environments for your self-hosted services, this streamlined setup can save hours of work. Feel free to contribute improvements or additional templates to the repo.

Happy self-hosting! 🔐🛠️

```

---

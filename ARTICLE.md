# 🚀 Using AWS CloudFormation to Create Test Authentication Servers for Pangolin and the Middleware Manager

This guide walks you through deploying preconfigured authentication servers using AWS CloudFormation templates. These temporary servers are ideal for testing Pangolin’s external authentication capabilities with middleware like **Authentik** or **Authelia**.

> 🛠️ This guide assumes you've already set up Pangolin and the [Middleware Manager](https://forum.hhf.technology/t/enhancing-your-pangolin-deployment-with-middleware-manager/1324).

---

## ☁️ Overview

We’ll use AWS CloudFormation to spin up a VPS that includes Docker and a chosen authentication stack. You’ll:

- Launch a CloudFormation stack from one of our templates
- SSH into your new EC2 instance
- Set up DNS records to point to the instance
- Confirm your authentication server is running
- Use Pangolin's Middleware Manager to protect resources with Authentik or Authelia

> 📄 Templates provided:
- `vps_ec2_base_docker.yaml`: A clean VPS with Docker pre-installed
- `vps_ec2_authelia.yaml`: Authelia auth server with Docker and TLS setup
- `vps_ec2_authentik.yaml`: Authentik auth server with Docker and TLS setup

---

## 🧱 Step 1: Generate or Select Your EC2 Key Pair

1. Go to [EC2 Key Pairs](https://console.aws.amazon.com/ec2)
2. Create a key pair (e.g., `VPS.pem`) and download it  
   _OR_  
   Make note of an existing one

> ⚠️ If using an existing key pair, ensure its name matches the one specified in the CloudFormation template, or edit the template to match your key pair.

---

## 📦 Step 2: Launch a CloudFormation Stack

1. Go to [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/home)
2. Click **"Create stack" > "With new resources (standard)"**
3. Choose **"Upload a template file"**, then upload one of the provided templates:
   - For example: `vps_ec2_authelia.yaml`
4. Click **Next**
5. Enter a **stack name** like `VPSStack`
6. Continue through the prompts and click **Create stack**

---

## 🔍 Step 3: Get Your Instance’s Public DNS

After the stack has been created:

1. Go to the [EC2 Console](https://console.aws.amazon.com/ec2)
2. Locate the new instance and copy its **Public DNS**

---

## 🔐 Step 4: SSH Into Your Instance

In your terminal or code editor:

```bash
cd /path/to/keypair
chmod 400 VPS.pem
ssh -i "VPS.pem" ubuntu@UNIQUE_ID.eu-west-1.compute.amazonaws.com
````

---

## 📋 Step 5: Verify Setup

After connecting:

```bash
cat /var/log/user-data.log
```

This log will show all setup steps including Docker installation and container start.

Start Docker services if needed:

```bash
sudo docker compose up -d
```

---

## 🌐 Step 6: Set Up DNS Records

In your DNS provider (e.g., Cloudflare):

1. Create a **CNAME** or **A record** for your auth server:

   * Example: `authelia.mydomain.com → EC2 Public DNS`
2. If using **Cloudflare**, go to SSL/TLS settings and set the mode to **Full**

> 🧠 Tip: Wait a few minutes for DNS propagation before accessing the server.

---

## ✅ Step 7: Test Your Authentication Server

Open your browser and visit:

```
https://authelia.mydomain.com
```

or for Authentik:

```
https://authentik.mydomain.com
```

If configured correctly, you should see the login UI for the respective platform.

---

## 🔄 Step 8: Integrate with Middleware Manager

1. Open the Pangolin Middleware Manager
2. Go to **Middlewares** tab
3. Ensure your `Authelia` or `Authentik` middleware is listed and correctly configured

   * Example for Authelia:

     ```yaml
     - id: authelia
       name: Authelia
       type: forwardAuth
       config:
         address: https://authelia.mydomain.com/api/verify
     ```
4. Go to **Dashboard > Manage** on the resource you want to protect
5. Click **Add Middleware**
6. Select your new external middleware (e.g., Authelia or Authentik)
7. Save and test

> 📸 Screenshot suggestion: Show attaching the middleware in the Middleware Manager UI.

---

## 🧪 Step 9: Confirm Login Flow

Visit your protected resource:

```
https://resourcename.mydomain.com
```

If configured correctly, you should be redirected to your authentication server, prompted to log in, and returned to the resource after authentication.

---

## ⚠️ Security Reminder

These templates are intended for **testing or short-term usage**:

* Update default credentials immediately
* Limit public access using security group rules or firewalls
* Regularly rotate secrets
* Never expose without a TLS certificate (included via certbot in the template)

---

## ✅ Summary

With these CloudFormation templates, you can stand up secure, Docker-based authentication servers in minutes. Whether you're testing **Authelia**, **Authentik**, or another identity provider, this setup is ideal for sandboxing external authentication for **Pangolin** resources.

---

## 🙏 Thanks for Reading

We hope this guide helps you quickly deploy and experiment with Pangolin’s external authentication features. If you run into issues or have suggestions for improving these templates, feel free to share them in the community forum!

Happy testing! 🔒🧪



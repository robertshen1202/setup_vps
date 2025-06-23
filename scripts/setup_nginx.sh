#!/usr/bin/env bash
set -euo pipefail

echo "Setting up Nginx server"

# List of environment variables to check
ENV_VARS=("DOMAIN" "EMAIL")

for var_name in "${ENV_VARS[@]}"; do
  if [[ -z "$var_name" ]]; then
    echo "Environment variable '$var_name' is NOT set."
    exit 1
  fi
done

NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"


echo "Installing Nginx and Certbot"
sudo apt-get update
sudo apt-get install -y nginx python3-certbot-nginx

echo "Creating nginx config for $DOMAIN at $NGINX_CONF"

  sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # Root path → "Hello World" in plain text
    location = / {
        default_type text/plain;
        return 200 "Hello World";
    }

    # Catch-all: return 404 for everything else
    location / {
        return 404;
    }
}
EOF

# Adding UFW rules
echo "Allowing http and https traffic through UFW"
sudo ufw allow http   # 80
sudo ufw allow https  # 443

# Enable site
echo "Enabling Nginx config: $NGINX_CONF"
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx


# Run certbot to configure SSL
echo "Requesting SSL certificate for $DOMAIN..."
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL"
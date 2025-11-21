FROM nginx:latest

COPY nginx.conf.template /etc/nginx/templates/default.conf.template

# Nginx Alpine image automatically runs envsubst on files in /etc/nginx/templates/ 
# and outputs them to /etc/nginx/conf.d/
# We just need to ensure ADB_HOSTNAME is passed as an env var.

EXPOSE 8080

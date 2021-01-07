#!/bin/sh
set -e

# NEEDS THE FOLLOWING PARAMETER:
# DOMAIN
# HEROKU_APP

# NEEDS THE FOLLOWING VARS IN ENV:
# CLOUDFLARE_EMAIL
# CLOUDFLARE_API_KEY
# HEROKU_API_KEY

# Only run once per week (Heroku scheduler runs daily)
if [ "$(date +%u)" = 1 ]
then
  # Download dependencies
  git clone https://github.com/acmesh-official/acme.sh
  cd ./acme.sh

  # Force ensures it doesnt fail because of lack of cron
  ./acme.sh --install --force

  # Map to environment variables that the ACME script requires
  export CF_Email=$CLOUDFLARE_EMAIL
  export CF_Key=$CLOUDFLARE_API_KEY

  # Generate wildcard certificate (this will take approx 130s)
  ~/.acme.sh/acme.sh  --issue -d $1  -d "*.$1"  --dns dns_cf

  # Update the certificate in the live app
  heroku certs:update "/app/.acme.sh/$1/fullchain.cer" "/app/.acme.sh/$1/$1.key" --confirm $2 --app $2
fi

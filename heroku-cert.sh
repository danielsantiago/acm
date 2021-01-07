#!/bin/sh
set -e

# NEEDS THE FOLLOWING PARAMETER:
# DOMAIN
# HEROKU_APP
# CF_Zone_ID

# NEEDS THE FOLLOWING VARS IN ENV:
# CLOUDFLARE_EMAIL
# CLOUDFLARE_API_TOKEN
# HEROKU_API_KEY

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -f | --force )
    force=1
    ;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

# Only run once per week (Heroku scheduler runs daily)
if [[ "$(date +%u)" = 1 || $force = 1 ]]
then

  echo "Running..."

  # Download dependencies
  git clone https://github.com/acmesh-official/acme.sh
  cd ./acme.sh

  # Force ensures it doesnt fail because of lack of cron
  ./acme.sh --install --force

  # Map to environment variables that the ACME script requires
  
  echo $CLOUDFLARE_EMAIL
  
  #export CF_Email=$CLOUDFLARE_EMAIL
  export CF_Token=$CLOUDFLARE_API_TOKEN
  
  # Get your Zone ID from the sidebar on the homepage of your Cloudflare Dashboard
  # Make sure you are using the 32 character alphanumeric ID that looks something like 81501ef88ef9b34f24450b63145d4019
  export CF_Zone_ID=$3

  # Generate wildcard certificate (this will take approx 130s)
  ~/.acme.sh/acme.sh --debug --issue -d $1  -d "*.$1"  --dns dns_cf

  # Update the certificate in the live app
  heroku certs:update "/app/.acme.sh/$1/fullchain.cer" "/app/.acme.sh/$1/$1.key" --confirm $2 --app $2
fi

echo "Done"

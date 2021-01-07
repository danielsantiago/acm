#!/bin/sh
set -e

# NEEDS HEROKU CLI BUILDPACK INSTALLED
# https://elements.heroku.com/buildpacks/heroku/heroku-buildpack-cli

# NEEDS THE FOLLOWING PARAMETER:
# DOMAIN
# HEROKU_APP

# NEEDS THE FOLLOWING VARS IN ENV:
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
  export CF_Token=$CLOUDFLARE_API_TOKEN
  
  # Generate wildcard certificate (this will take approx 130s)
  ~/.acme.sh/acme.sh --issue -d $1  -d "*.$1"  --dns dns_cf

  # Update the certificate in the live app
  heroku certs:add "/app/.acme.sh/$1/fullchain.cer" "/app/.acme.sh/$1/$1.key" --confirm $2 --app $2
fi

echo "Done"

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
  -i | --init )
    init=1
    ;;
  -f | --force )
    force=1
    ;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi

# Only run once per week (Heroku scheduler runs daily)
if [[ "$(date +%u)" = 1 || $first = 1 || $force = 1 ]]
then

  echo "Running..."

  # Download dependencies
  git clone https://github.com/acmesh-official/acme.sh
  cd ./acme.sh

  # Force ensures it doesnt fail because of lack of cron
  ./acme.sh --install --force
  
  # Tell Acme to use Letsencrypt as default CA
  ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

  # Map to environment variables that the ACME script requires
  export CF_Token=$CLOUDFLARE_API_TOKEN
  
  # Generate wildcard certificate (this will take approx 130s)
  ~/.acme.sh/acme.sh --issue -d $1  -d "*.$1"  --dns dns_cf

  echo "fullchain.cer content:"
  cat "/app/.acme.sh/$1/fullchain.cer"
  
  echo "$1.key content:"
  cat "/app/.acme.sh/$1/$1.key"

  # Update the certificate in the live app
  if [[ $first = 1 ]]
  then
      heroku certs:add --domains="*.$1" "/app/.acme.sh/$1/fullchain.cer" "/app/.acme.sh/$1/$1.key" --app $2
  else
      heroku certs:update "/app/.acme.sh/$1/fullchain.cer" "/app/.acme.sh/$1/$1.key" --app $2
  fi
fi

echo "Done"

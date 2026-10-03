#!/usr/bin/env bash
# Deploys new images on the demo server. Called through SSM (no SSH) by the sotto-deploy
# document that each app repo's images.yml triggers:
#   deploy.sh <tag> <service> [service...]     e.g. deploy.sh sha-1a2b3c4 api worker
#   deploy.sh bootstrap                        first boot: config, secrets, backing services
# Steps: sync config from S3 → write .env from SSM → record tags → pull → migrate → up --wait.
set -euo pipefail
cd /opt/sotto

# Written once by user-data: AWS_REGION, CONFIG_BUCKET, FILES_BUCKET, ECR_REGISTRY.
# shellcheck disable=SC1091
source ./instance.env

log() { echo "[deploy $(date -u +%H:%M:%S)] $*"; }

log "syncing config from s3://$CONFIG_BUCKET/demo/"
aws s3 sync "s3://$CONFIG_BUCKET/demo/" /opt/sotto/ --no-progress \
  --exclude ".env" --exclude "tags.env" --exclude "instance.env"
chmod +x deploy.sh backup.sh

touch tags.env
if [ "${1:-}" != "bootstrap" ]; then
  tag="${1:?usage: deploy.sh <tag> <service...>}"
  shift
  for service in "$@"; do
    case "$service" in web | api | worker | transcriber) ;; *) log "unknown service $service"; exit 2 ;; esac
    key="$(echo "$service" | tr '[:lower:]' '[:upper:]')_TAG"
    sed -i "/^${key}=/d" tags.env
    echo "${key}=${tag}" >> tags.env
  done
fi

log "writing .env from SSM /sotto/demo/ (values never printed)"
umask 077
{
  cat instance.env tags.env
  aws ssm get-parameters-by-path --path /sotto/demo/ --with-decryption \
    --query 'Parameters[].[Name,Value]' --output text |
    while IFS=$'\t' read -r name value; do echo "${name##*/}=${value}"; done
} > .env.next
mv .env.next .env

aws ecr get-login-password --region "$AWS_REGION" |
  docker login --username AWS --password-stdin "$ECR_REGISTRY" > /dev/null

log "starting backing services"
docker compose up -d --wait postgres redis rabbitmq mailpit caddy
# The Caddyfile is a bind mount: pick up edits without dropping connections.
docker compose exec -T caddy caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile || true

# Only services that have been deployed at least once have a tag.
mapfile -t apps < <(sed -n 's/^\([A-Z]*\)_TAG=.*/\1/p' tags.env | tr '[:upper:]' '[:lower:]')
if [ "${#apps[@]}" -eq 0 ]; then
  log "no app images deployed yet; backing services are up"
  exit 0
fi

log "pulling ${apps[*]}"
docker compose pull "${apps[@]}"

if printf '%s\n' "${apps[@]}" | grep -qx api; then
  log "running database migrations"
  docker compose run --rm migrate
fi

log "starting ${apps[*]} and waiting for health checks"
docker compose up -d --wait --remove-orphans caddy "${apps[@]}"
docker image prune -af --filter "until=72h" > /dev/null
log "done: $(paste -sd' ' tags.env)"

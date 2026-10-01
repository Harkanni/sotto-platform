#!/usr/bin/env bash
# Nightly Postgres backup to S3 (run by a systemd timer set up in user-data).
# The bucket's lifecycle rule deletes backups after 14 days. Restore drill in docs/runbooks.
set -euo pipefail
cd /opt/sotto
# shellcheck disable=SC1091
source ./instance.env
key="backups/sotto-$(date -u +%Y-%m-%dT%H%M).dump"
docker compose exec -T postgres pg_dump -U sotto -d sotto --format=custom |
  aws s3 cp - "s3://$FILES_BUCKET/$key" --no-progress
echo "backup written to s3://$FILES_BUCKET/$key"

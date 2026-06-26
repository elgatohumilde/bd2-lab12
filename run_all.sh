#!/usr/bin/env bash
set -euox pipefail

docker compose down
docker compose up -d
trap 'docker compose down' EXIT

sleep 1

psql -f p1.sql
psql -f p2.sql
psql -p 5433 -f p3_remote.sql
psql -f p3_principal.sql

#!/usr/bin/env sh
set -eu

# Contrato de configuración (variables de entorno) :
# DB_HOST=svc-db, DB_PORT=5432, DB_NAME=appdb, DB_USER/DB_PASSWORD desde Secret
# Espera DBHOST/DBUSER/DBPASS/DBNAME y usa puerto por defecto.
export DBHOST="${DBHOST:-${DB_HOST:-}}"
export DBUSER="${DBUSER:-${DB_USER:-}}"
export DBPASS="${DBPASS:-${DB_PASSWORD:-}}"
export DBNAME="${DBNAME:-${DB_NAME:-}}"

# Validación para arrancar leyendo DB_*
: "${DBHOST:?Falta DB_HOST (o DBHOST)}"
: "${DBUSER:?Falta DB_USER (o DBUSER)}"
: "${DBPASS:?Falta DB_PASSWORD (o DBPASS)}"
: "${DBNAME:?Falta DB_NAME (o DBNAME)}"

# Puerto de Flask/Gunicorn (el Service de K8s puede exponer 80 hacia targetPort 5000)
export PORT="${PORT:-5000}"

exec "$@"
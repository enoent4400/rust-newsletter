set -x
set -eo pipefail

if ! [ -x "$(command -v psql)" ]; then
  echo 'Error: psql is not installed.' >&2
  exit 1
fi

if ![ -x "$(command -v sqlx)" ]; then
  echo 'Error: sqlx is not installed.' >&2
  echo 'Run `cargo instal --verion=0.5.7 sqlx-cli --no-default-features --features postgres` to install sqlx.' >&2
  exit 1
fi

#Check if a custom user has been set, oterwise use the default 'postgres'
DB_USER="${POSTGRES_USER:=postgres}"

#Check if a custom password has been set, oterwise use the default 'postgres'
DB_PASSWORD="${POSTGRES_PASSWORD:=postgres}"

#Check if a custom database name has been set, oterwise use the default 'postgres'
DB_NAME="${POSTGRES_DB:=newsletter}"

#Check if a custom port has been set, oterwise use the default '5432'
DB_PORT="${POSTGRES_PORT:=5432}"

if [[ -z "${SKIP_DOCKER}" ]]
then
    docker run \
        -e POSTGRES_USER=${DB_USER} \
        -e POSTGRES_PASSWORD=${DB_PASSWORD} \
        -e POSTGRES_DB=${DB_NAME} \
        -p "${DB_PORT}":5432 \
        -d postgres \
        postgres -N 1000
fi


#kepp checking if the database is ready to accept connections
export  PGPASSWORD="${DB_PASSWORD}"
until  psql -h localhost -U ${DB_USER} -p ${DB_PORT} -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up, running on port ${DB_PORT} - executing migrations"

#Launch postgres using Docker
export DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}
sqlx database create
sqlx migrate run

>&2 echo "Postgres has been migrated, ready to go!"
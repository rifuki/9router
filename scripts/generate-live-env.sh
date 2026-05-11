#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
ENV_FILE=${1:-"$ROOT_DIR/.env"}
EXAMPLE_FILE="$ROOT_DIR/.env.example"

if [ ! -f "$EXAMPLE_FILE" ]; then
  printf 'Missing %s\n' "$EXAMPLE_FILE" >&2
  exit 1
fi

rand_hex() {
  bytes=$1

  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "$bytes"
    return
  fi

  od -An -N "$bytes" -tx1 /dev/urandom | tr -d ' \n'
  printf '\n'
}

JWT_SECRET=$(rand_hex 48)
INITIAL_PASSWORD=$(rand_hex 12)

if [ ! -f "$ENV_FILE" ]; then
  cp "$EXAMPLE_FILE" "$ENV_FILE"
fi

TMP_FILE=$(mktemp)
FOUND_JWT=0
FOUND_PASSWORD=0

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    JWT_SECRET=*)
      printf 'JWT_SECRET=%s\n' "$JWT_SECRET"
      FOUND_JWT=1
      ;;
    INITIAL_PASSWORD=*)
      printf 'INITIAL_PASSWORD=%s\n' "$INITIAL_PASSWORD"
      FOUND_PASSWORD=1
      ;;
    *)
      printf '%s\n' "$line"
      ;;
  esac
done < "$ENV_FILE" > "$TMP_FILE"

if [ "$FOUND_JWT" -eq 0 ]; then
  printf 'JWT_SECRET=%s\n' "$JWT_SECRET" >> "$TMP_FILE"
fi

if [ "$FOUND_PASSWORD" -eq 0 ]; then
  printf 'INITIAL_PASSWORD=%s\n' "$INITIAL_PASSWORD" >> "$TMP_FILE"
fi

mv "$TMP_FILE" "$ENV_FILE"
chmod 600 "$ENV_FILE" 2>/dev/null || true

printf 'Generated %s\n' "$ENV_FILE"
printf 'JWT_SECRET=%s\n' "$JWT_SECRET"
printf 'INITIAL_PASSWORD=%s\n' "$INITIAL_PASSWORD"

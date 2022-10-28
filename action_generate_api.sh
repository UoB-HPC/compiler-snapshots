#!/usr/bin/env bash

set -eu

VARIANT=$1
OUT=$2
builds="builds-$VARIANT.json"
readarray -t keys < <(jq -r 'keys | .[]' "$builds")
mkdir -p "$OUT/$VARIANT"
for key in "${keys[@]}"; do
  jq -c ".\"$key\"" "$builds" >"$OUT/$VARIANT/$key.json" &
done
wait
echo "Done"

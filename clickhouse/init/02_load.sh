#!/bin/bash
# Загружает data/train.csv в transactions_db.transactions при первом старте контейнера.
set -euo pipefail

if [ ! -f /data/train.csv ]; then
    echo "WARNING: /data/train.csv not found, table transactions_db.transactions stays empty" >&2
    exit 0
fi

clickhouse-client \
    --date_time_input_format=best_effort \
    --query "INSERT INTO transactions_db.transactions FORMAT CSVWithNames" < /data/train.csv

echo "Loaded rows: $(clickhouse-client --query 'SELECT count() FROM transactions_db.transactions')"

#!/usr/bin/env bash
set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rendered="$(helm template integer-overrides "$chart_dir" \
  --set runtime.limits.maxRequestBytes=2097152 \
  --set runtime.limits.maxBatchSize=2 \
  --set runtime.limits.maxRowsPerSeries=16 \
  --set runtime.limits.maxContextSteps=4096 \
  --set runtime.limits.maxPredictionLength=96 \
  --set runtime.limits.maxOutputElements=123456)"

for expected in \
  '{name: MAX_REQUEST_BYTES, value: "2097152"}' \
  '{name: MAX_BATCH_SIZE, value: "2"}' \
  '{name: MAX_ROWS_PER_SERIES, value: "16"}' \
  '{name: MAX_CONTEXT_STEPS, value: "4096"}' \
  '{name: MAX_PREDICTION_LENGTH, value: "96"}' \
  '{name: MAX_OUTPUT_ELEMENTS, value: "123456"}'; do
  if ! grep -Fq -- "$expected" <<<"$rendered"; then
    printf 'Expected integer limit env entry missing: %s\n' "$expected" >&2
    exit 1
  fi
done

printf 'Integer limit overrides render as decimal environment strings.\n'

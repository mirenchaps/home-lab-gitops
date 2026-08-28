#!/usr/bin/env bash
# Generates steady serial load against the qwen predictor so Prometheus has
# something to measure. Re-run this unchanged during chaos experiments -- a
# baseline is only comparable if the load that produced it is identical.
set -uo pipefail

ENDPOINT="${ENDPOINT:-http://192.168.0.38:30082/openai/v1/chat/completions}"
DURATION="${DURATION:-300}"
MAX_TOKENS="${MAX_TOKENS:-128}"

# Fixed prompt and fixed max_tokens: varying either changes token counts and
# makes latency numbers incomparable between runs.
PROMPT="Explain what a Kubernetes DaemonSet is in two sentences."

body=$(cat <<JSON
{
  "model": "qwen",
  "max_tokens": ${MAX_TOKENS},
  "messages": [{"role": "user", "content": "${PROMPT}"}]
}
JSON
)

end=$(( $(date +%s) + DURATION ))
ok=0
fail=0

echo "Load against ${ENDPOINT}"
echo "Duration ${DURATION}s, max_tokens ${MAX_TOKENS}, serial (one in flight)"
echo "Started $(date '+%H:%M:%S') -- note this time, you will need it to read the graphs"
echo

while (( $(date +%s) < end )); do
  if curl -sf -X POST "${ENDPOINT}" \
       -H 'Content-Type: application/json' \
       -d "${body}" \
       -o /dev/null; then
    (( ok++ ))
  else
    (( fail++ ))
  fi
  printf '\rok=%d fail=%d remaining=%ds ' "${ok}" "${fail}" "$(( end - $(date +%s) ))"
done

echo
echo
echo "Finished $(date '+%H:%M:%S')"
echo "Completed ${ok}, failed ${fail}"

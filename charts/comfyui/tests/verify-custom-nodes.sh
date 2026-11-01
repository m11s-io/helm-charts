#!/usr/bin/env bash
# Exercise the init/runtime filesystem boundary with the published generic image.
set -euo pipefail
chart=$(cd "$(dirname "$0")/.." && pwd)
image=${COMFYUI_TEST_IMAGE:-m11s/comfyui:0.43.0-cuda@sha256:35a3d64564919e45872c61cec4fc1d3a4cf8740cc32834056fe93ccaa6d66e5e}
work=$(mktemp -d)
container="comfyui-extensions-test-$$"
cleanup() {
  docker rm -f "$container" >/dev/null 2>&1 || true
  docker run --rm --pull never --platform linux/amd64 --user 0:0 \
    -v "$work/environment:/environment" --entrypoint chmod "$image" -R a+rwX /environment >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT
mkdir "$work/environment" "$work/config"
chmod 777 "$work/environment"
cp "$chart/files/custom_nodes.py" "$work/config/custom_nodes.py"
cat > "$work/config/config.json" <<'JSON'
{"url":"http://127.0.0.1:8188","repositories":[{"name":"ComfyUI-GGUF","repository":"https://github.com/city96/ComfyUI-GGUF.git","revision":"6ea2651e7df66d7585f6ffee804b20e92fb38b8a","requirements":"requirements.txt","expectedNodes":["UnetLoaderGGUF","CLIPLoaderGGUF"]},{"name":"comfyui-krea2-conditioning","repository":"https://github.com/huwhitememes/comfyui-krea2-conditioning.git","revision":"729cda4fade982988a375b01928f515458407a5c","expectedNodes":["ConditioningKrea2Rebalance"]}]}
JSON
mounts=(-v "$work/environment:/opt/comfyui-extensions" -v "$work/config:/etc/comfyui-extensions:ro")
docker run --rm --platform linux/amd64 --user 10001:10001 "${mounts[@]}" \
  --entrypoint /opt/venv/bin/python "$image" /etc/comfyui-extensions/custom_nodes.py install
# A second container must consume the installation without inherited writable layers.
docker run -d --platform linux/amd64 --name "$container" --user 10001:10001 "${mounts[@]}" \
  --entrypoint /opt/venv/bin/python "$image" /etc/comfyui-extensions/custom_nodes.py run -- --cpu --listen 127.0.0.1 --port 8188 >/dev/null
for attempt in $(seq 1 120); do
  if docker exec "$container" /opt/venv/bin/python /etc/comfyui-extensions/custom_nodes.py ready 2>/dev/null; then
    echo 'GGUF and Krea 2 conditioning classes registered from shared environment'
    exit 0
  fi
  if [[ $(docker inspect --format '{{.State.Running}}' "$container") != true ]]; then
    break
  fi
  sleep 1
done
docker logs "$container"
echo 'Custom-node runtime verification failed' >&2
exit 1

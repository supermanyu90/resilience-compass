# Deploying Resilience Compass on SUSE K3s (+ optional NVIDIA NIM)

This runs the whole app **on-prem / at the edge** on **SUSE K3s** (lightweight Kubernetes), with local
Gemma inference. Inference stays on the cluster, so the offline / privacy-first story holds.

Partner products used:
- **SUSE** — **K3s** (edge Kubernetes) + **Rancher/Traefik** ingress; storage via the Rancher
  `local-path` provisioner. Optionally **NeuVector** (zero-trust container security) and **Longhorn** (HA
  storage) on the same cluster.
- **NVIDIA** — swap the model backend to a **Gemma NIM** microservice (OpenAI-compatible), optionally on
  an **NVIDIA GPU** node via the **GPU Operator** (both bundled in **SUSE AI**).
- **Nebius** — **Nebius AI Studio** (hosted, OpenAI-compatible) as a cloud / no-GPU inference tier — the
  same backend switch, zero code change.

The web app (`serve.js`) is **backend-agnostic**: the browser always speaks the same API, and the proxy
translates to Ollama *or* any OpenAI-compatible endpoint (NIM). Flip backends with two env vars — no
front-end change. (Verified locally by pointing the openai backend at Ollama's own `/v1` endpoint.)

```
Browser ──/api/*──▶ webapp (serve.js)
                       ├─ MODEL_BACKEND=ollama ─▶ ollama Service :11434   (native /api/*)
                       └─ MODEL_BACKEND=openai ─▶ nim Service :8000/v1    (NVIDIA NIM, OpenAI API)
```

## 1. Build the web image and import it into K3s
```bash
# from the project root (resilience_compass_mobile/)
docker build -f deploy/Dockerfile -t resilience-compass-web:0.1 .

# make the local image available to K3s' containerd:
docker save resilience-compass-web:0.1 | sudo k3s ctr images import -
```

## 2. Deploy (default: local Ollama)
```bash
kubectl apply -f deploy/k8s/00-namespace.yaml
kubectl apply -f deploy/k8s/10-ollama.yaml
kubectl apply -f deploy/k8s/20-model-pull-job.yaml     # pulls gemma3:4b into the Ollama volume
kubectl apply -f deploy/k8s/30-webapp.yaml
kubectl apply -f deploy/k8s/40-ingress.yaml

kubectl -n resilience-compass get pods,svc
```
Add `resilience.local` to your `/etc/hosts` pointing at the node IP, then open **http://resilience.local**.
(No ingress? `kubectl -n resilience-compass port-forward svc/webapp 8080:80` → http://localhost:8080.)

## 3. Optional: use NVIDIA NIM instead of Ollama
Needs an NVIDIA GPU node + the GPU Operator + an NGC key.
```bash
# registry pull secret for nvcr.io
kubectl -n resilience-compass create secret docker-registry ngc-registry \
  --docker-server=nvcr.io --docker-username='$oauthtoken' --docker-password=$NGC_API_KEY

# set your NGC key + verify the Gemma NIM image tag in deploy/k8s/nim/nim.yaml, then:
kubectl apply -f deploy/k8s/nim/nim.yaml

# point the app at NIM (edit deploy/k8s/30-webapp.yaml ConfigMap):
#   MODEL_BACKEND: "openai"
#   OPENAI_BASE_URL: "http://nim:8000/v1"
#   MODEL_ID: "google/gemma-3-4b-it"
kubectl apply -f deploy/k8s/30-webapp.yaml
kubectl -n resilience-compass rollout restart deploy/webapp
```

## 3b. Optional: Nebius AI Studio (cloud tier — no local GPU)

Nebius AI Studio is a hosted, **OpenAI-compatible** inference API, so `serve.js` uses it unchanged. Good
as a **no-GPU demo path** or a cloud **"burst" tier**. Keep local Ollama as the private, offline default —
don't route sensitive incident/BCM text to the cloud if you're claiming on-device/privacy-first.

**Run the demo directly against Nebius (lowest effort):**
```bash
MODEL_BACKEND=openai \
OPENAI_BASE_URL=https://api.studio.nebius.com/v1 \
OPENAI_API_KEY=<your-nebius-key> \
MODEL_ID=google/gemma-2-9b-it \
node demo_preview/serve.js          # → http://localhost:8422, now served by Nebius
```

**On the cluster:**
```bash
# put your key in deploy/k8s/nebius/nebius.yaml, then:
kubectl apply -f deploy/k8s/nebius/nebius.yaml                       # Secret + Nebius ConfigMap
kubectl -n resilience-compass set env deployment/webapp --from=secret/model-api
kubectl -n resilience-compass rollout restart deploy/webapp
```
Verify a **Gemma** variant is in the Nebius catalog and confirm the exact base URL / model id.

## 4. Optional: harden with SUSE NeuVector
```bash
helm repo add neuvector https://neuvector.github.io/neuvector-helm/ && helm repo update
helm install neuvector neuvector/core -n neuvector --create-namespace
```
NeuVector then gives runtime zero-trust protection for the banking workload — operational resilience
includes security.

## Notes
- `serve.js` env: `MODEL_BACKEND` (`ollama`|`openai`), `OLLAMA_URL`, `OPENAI_BASE_URL`, `OPENAI_API_KEY`, `MODEL_ID`, `PORT`.
- Everything is local to the cluster — pull the model once, then it runs offline (airplane-mode friendly).
- GPU is optional for Ollama; **required** for NIM.

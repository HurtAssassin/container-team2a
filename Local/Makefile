KUBE_CONTEXT := docker-desktop
NAMESPACE := container-team2a
KUSTOMIZE_DIR := ./k8s/overlays/local

.PHONY: up down redeploy status wait context namespace

context:
	kubectl config use-context $(KUBE_CONTEXT)

namespace:
	kubectl create ns $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -

up: context namespace
	kubectl apply -k $(KUSTOMIZE_DIR)
	kubectl wait --for=condition=ready pod -l app=app-web -n $(NAMESPACE) --timeout=180s
	kubectl wait --for=condition=complete job/db-init-schema -n $(NAMESPACE) --timeout=180s
	kubectl rollout status deployment/cf-quick-tunnel -n $(NAMESPACE) --timeout=120s
	powershell -NoProfile -Command "$$u = (kubectl logs deployment/cf-quick-tunnel -n $(NAMESPACE) --tail=200 | Select-String -Pattern 'https://.*trycloudflare.com' | Select-Object -Last 1).Matches.Value; if (-not $$u) { Write-Error 'Tunnel URL not found'; exit 1 }; $$code = (Invoke-WebRequest -UseBasicParsing -Uri $$u -Method Get).StatusCode; Write-Host ('HTTP Status: ' + $$code); if ($$code -ne 200) { exit 1 }"

down: context
	kubectl delete -k $(KUSTOMIZE_DIR) --ignore-not-found=true

redeploy: down up

status: context
	kubectl get all -n $(NAMESPACE)

wait: context
	kubectl wait --for=condition=ready pod -l app=app-web -n $(NAMESPACE) --timeout=180s

.PHONY: tunnel-url tunnel-logs

tunnel-logs: context
	kubectl logs deployment/cf-quick-tunnel -n $(NAMESPACE) --tail=200

tunnel-url: context
	kubectl logs deployment/cf-quick-tunnel -n $(NAMESPACE) --tail=200 | findstr /i "trycloudflare.com"

.PHONY: test

test: context
	powershell -NoProfile -Command "$$u = (kubectl logs deployment/cf-quick-tunnel -n $(NAMESPACE) --tail=200 | Select-String -Pattern 'https://.*trycloudflare.com' | Select-Object -Last 1).Matches.Value; if (-not $$u) { Write-Error 'Tunnel URL not found in logs'; exit 1 }; $$code = (Invoke-WebRequest -UseBasicParsing -Uri $$u -Method Get).StatusCode; Write-Host ('HTTP Status: ' + $$code); if ($$code -ne 200) { exit 1 }"
# Kubernetes local (Docker Desktop) - Stack automatizado (Team 2A)

## Requisitos
- Docker Desktop con Kubernetes habilitado (contexto: `docker-desktop`)
- kubectl instalado
- GNU Make (Windows: instalado vía Chocolatey)
- Acceso a internet (Cloudflare Quick Tunnel)

## Estructura
- `k8s/base`: manifiestos base (DB, app, ingress, job, tunnel)
- `k8s/overlays/local`: overlay local (labels y ajustes)
- `Makefile`: orquestación (1 comando = deploy + validación + túnel + test)

## Despliegue (1 comando)
```powershell
make up
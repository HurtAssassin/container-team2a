# Despliegue EKS: Flask + PostgreSQL (Kubernetes)

Este directorio contiene manifiestos para desplegar una app Flask con PostgreSQL en Amazon EKS.

## 1) Que incluye este despliegue

- Namespace: `container-team2a`
- Base de datos: PostgreSQL en `StatefulSet` (`db`)
- Persistencia: PVC `postgres-pvc` con `storageClassName: gp2`
- App web: Deployment `app-web` (2 replicas)
- Servicios:
  - `svc-db` (headless) para PostgreSQL
  - `app-service` (ClusterIP)
  - `app-service-external` (LoadBalancer)

## 2) Archivos y funcion

- `00-namespace.yaml`: crea namespace
- `01-secret-db.yaml`: credenciales DB
- `02-pvc-postgres.yaml`: volumen persistente para postgres
- `03-svc-postgres.yaml`: service headless para StatefulSet
- `08-configmap-postgres-init.yaml`: script SQL inicial
- `04-statefulset-postgres.yaml`: postgres con `PGDATA`
- `05-deployment-app.yaml`: app flask
- `06-service-app.yaml`: servicio interno app
- `07-service-app-external.yaml`: servicio externo app
- `kustomization.yaml`: despliegue de todo en un solo comando

## 3) Prerrequisitos en AWS/EKS

Define variables (ajusta con tus valores):

```powershell
$CLUSTER_NAME="<tu-cluster>"
$REGION="<tu-region>"
$ACCOUNT_ID="518893644310"
$PRINCIPAL_ARN="arn:aws:iam::$ACCOUNT_ID:user/salvador-admin"
```

### 3.1 Dar acceso al usuario/rol dentro del cluster EKS

Si te aparece error como `cannot list resource "nodes"`, asigna acceso cluster-admin:

```powershell
aws eks create-access-entry --cluster-name $CLUSTER_NAME --principal-arn $PRINCIPAL_ARN --type STANDARD --region $REGION

aws eks associate-access-policy --cluster-name $CLUSTER_NAME --principal-arn $PRINCIPAL_ARN --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope type=cluster --region $REGION
```

Actualizar contexto kubeconfig:

```powershell
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION
```

### 3.2 Instalar addon de EBS CSI (obligatorio para PVC en EKS)

Comando solicitado:

```powershell
aws eks create-addon --cluster-name <tu-cluster> --addon-name aws-ebs-csi-driver
```

Version con variables:

```powershell
aws eks create-addon --cluster-name $CLUSTER_NAME --addon-name aws-ebs-csi-driver --region $REGION
```

Verificar que este corriendo:

```powershell
kubectl get pods -n kube-system | findstr ebs-csi
kubectl get csidriver
kubectl get storageclass
```

### 3.3 Permisos IAM para el CSI driver

Si en logs ves `UnauthorizedOperation` para EC2, agrega policy al rol usado por el driver.

Solucion rapida (si el driver usa NodeInstanceRole):

```powershell
aws iam attach-role-policy --role-name <NodeInstanceRole> --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy
```

Despues reinicia el controller:

```powershell
kubectl rollout restart deployment ebs-csi-controller -n kube-system
kubectl get pods -n kube-system | findstr ebs-csi-controller
```

## 4) Despliegue de la aplicacion (un solo comando)

Desde la raiz del proyecto:

```powershell
kubectl apply -k k8s/rol-c-k8s
```

## 5) Verificacion

```powershell
kubectl get ns
kubectl get all -n container-team2a
kubectl get pvc -n container-team2a
kubectl get pods -n container-team2a -w
```

Esperado:

- PVC `postgres-pvc` en `Bound`
- Pod `db-0` en `Running`
- Pods `app-web-*` en `Running`

## 6) Logs utiles

Postgres:

```powershell
kubectl logs -n container-team2a db-0 -c postgres
```

Postgres (contenedor anterior, util para crashloop):

```powershell
kubectl logs -n container-team2a db-0 -c postgres --previous
```

App:

```powershell
kubectl logs -n container-team2a deployment/app-web
```

## 7) Acceso a la app

Local via port-forward:

```powershell
kubectl port-forward -n container-team2a svc/app-service 5000:5000
```

Abrir: `http://localhost:5000`

Cloud via LoadBalancer:

```powershell
kubectl get svc app-service-external -n container-team2a
```

Usar `EXTERNAL-IP` o DNS asignado.

## 8) Problemas comunes y solucion

### 8.1 Pod `db-0` queda en `Pending`

Revisar:

```powershell
kubectl describe pod db-0 -n container-team2a
kubectl describe pvc postgres-pvc -n container-team2a
```

Si sale `no storage class is set`: revisar `02-pvc-postgres.yaml` (`storageClassName: gp2`).

### 8.2 `Waiting for a volume to be created by ebs.csi.aws.com`

Falta addon CSI o permisos IAM. Revisar secciones 3.2 y 3.3.

### 8.3 `MountVolume.SetUp failed ... configmap "postgres-init-sql" not found`

Asegura aplicar todo con kustomize:

```powershell
kubectl apply -k k8s/rol-c-k8s
```

### 8.4 `BackOff restarting failed container postgres`

Revisar logs:

```powershell
kubectl logs -n container-team2a db-0 -c postgres --previous
```

Ya esta mitigado en manifiesto con:

- `PGDATA=/var/lib/postgresql/data/pgdata`

## 9) Reaplicar desde cero (solo este namespace)

```powershell
kubectl delete -k k8s/rol-c-k8s
kubectl apply -k k8s/rol-c-k8s
```

## 10) Limpieza total

```powershell
kubectl delete -k k8s/rol-c-k8s
```

## 11) Seguridad recomendada

- No usar usuario root para operar EKS.
- Usar un rol/usuario dedicado (ej: `salvador-admin`) con Access Entry en el cluster.
- Implementar IRSA para `aws-ebs-csi-driver` como solucion recomendada a largo plazo.
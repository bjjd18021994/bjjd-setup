# Jenkins Installation Guide on Kubernetes

## ✅ Prerequisites

Before deploying Jenkins, ensure the following requirements are met:

1. You have a running Kubernetes cluster (e.g., Docker Desktop with Kubernetes enabled).
2. Helm CLI is installed and configured.
3. Windows drive (e.g., `C:`) is shared with Docker Desktop so it is accessible at `/mnt/c/...` inside the cluster node VM.
4. A directory such as `C:\k8s-data\jenkins` exists on Windows and maps to `/mnt/c/k8s-data/jenkins` inside the Kubernetes node.

---

## 🚀 Deployment Steps

### 1. Create the target directory on Windows

```powershell
mkdir C:\k8s-data\jenkins
```

### 2. Verify that the directory is accessible inside the node

```bash
wsl -d docker-desktop
ls /mnt/c/k8s-data/jenkins
```

---

## 3. Volume Mount Inside `pv.yaml`

Use the following mount path inside the Kubernetes PersistentVolume configuration:

* Defined mount path in `pv.yaml`:

  ```
  /run/desktop/mnt/host/c/k8s-data/jenkins
  ```

* At runtime, Kubernetes resolves this path to:

  ```
  /tmp/docker-desktop-root/run/desktop/mnt/host/c/k8s-data/jenkins
  ```
* Give access to the k8s folder and its subfolder inside docker-desktop otherwise you may get the error of permission denied: **/mnt/host/c/k8s-data/jenkins**

```bash
cd /tmp/docker-desktop-root/run/desktop/mnt/host/c
chmod -R 777 k8s-data
```

(Adjust permissions to your security requirements — `777` is permissive but effective for local development.)

---

## 4. Jenkins Helm Chart Structure

The Jenkins Helm chart is stored under:

```
bjjd-setup/kubernetes/jenkins/jenkins-chart
```

### Chart File Structure

```
jenkins-chart/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── pv.yaml
    ├── pvc.yaml
    └── service.yaml
```

---

## 5. Install Jenkins via Helm

Run the following command from the directory containing the chart:

```powershell
C:\> helm install jenkins .\jenkins-chart
```

---

## 6. Port Forward Jenkins to Your Browser

```bash
kubectl port-forward svc/jenkins 8080:8080
```

---

## 7. Access Jenkins in a Browser

Open:

```
http://localhost:8080/
```

---

## 8. Retrieve the Jenkins Admin Password

Option A — From Kubernetes Secret:

```bash
kubectl get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 -d
```

Option B — From inside the Jenkins pod:

```bash
kubectl exec -it -n jenkins <jenkins-pod-name> -- cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## 🎉 Jenkins is now ready to use!

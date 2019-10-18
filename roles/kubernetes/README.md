# Kubernetes

Install and setup [Kubernetes](https://kubernetes.io/) tools:

- [`kubectl`](https://kubernetes.io/docs/reference/kubectl/)
- [`kubeadm`](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)
- [`kubelet`](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)
- [`minikube`](https://kubernetes.io/docs/setup/learning-environment/minikube/)

Variables:

- `kubernetes_version`: kubernetes version for `kubectl`, `kubeadm` and `kubelet`, e.g. `1.16`. Defaults to latest available in Kubernetes repository
- `install_kubectl`: whether to install `kubectl` or not. Defaults to True
- `install_kubeadm`: whether to install `kubeadm` or not. Defaults to False
- `install_kubelet`: whether to install `kubelet` or not. Defaults to False
- `minikube_version`: minikube version to install, e.g. `1.4.0`. Defaults to latest available in Kubernetes repository
- `install_minikube`: whether to install `minikube` or not. Defaults to False

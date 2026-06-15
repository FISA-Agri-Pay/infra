#!/usr/bin/env bash
set -euo pipefail

MANIFEST="${MANIFEST:-/home/ubuntu/postgres-ha-etcd.yaml}"
NAMESPACE="${NAMESPACE:-postgres-ha}"
STATEFULSET="${STATEFULSET:-patroni-etcd}"

echo "[1/5] Checking target node..."
kubectl get node k8s-worker-ai-node -o wide

echo
echo "[2/5] Applying manifest: ${MANIFEST}"
kubectl apply -f "${MANIFEST}"

echo
echo "[3/5] Waiting for etcd StatefulSet rollout..."
kubectl -n "${NAMESPACE}" rollout status "statefulset/${STATEFULSET}" --timeout=180s

echo
echo "[4/5] Current etcd resources..."
kubectl -n "${NAMESPACE}" get pod,svc -o wide

echo
echo "[5/5] Checking etcd health from inside the pod..."
kubectl -n "${NAMESPACE}" exec "statefulset/${STATEFULSET}" -- \
  /usr/local/bin/etcdctl --endpoints=http://127.0.0.1:2379 endpoint health

echo
echo "Done."
echo "Use this etcd endpoint from PostgreSQL servers:"
echo "  http://192.168.100.22:32379"

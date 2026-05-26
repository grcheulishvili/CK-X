#!/bin/bash
# Validate that the restricted pod exists and that the api-server-policy is structured
# to block the API server for non-admin (default-selected) pods.
#
# NOTE: The cluster CNI (flannel) does NOT enforce NetworkPolicy at runtime, so we
# validate the POLICY SPEC rather than live connectivity. Checking actual connectivity
# here would incorrectly fail a correct answer.

NAMESPACE="api-restrict"
POD_NAME="restricted-pod"
POLICY_NAME="api-server-policy"

# Namespace exists
kubectl get namespace "$NAMESPACE" &> /dev/null || { echo "❌ Namespace '$NAMESPACE' not found"; exit 1; }

# restricted-pod exists with correct label
kubectl get pod "$POD_NAME" -n "$NAMESPACE" &> /dev/null || { echo "❌ Pod '$POD_NAME' not found in '$NAMESPACE'"; exit 1; }
POD_LABEL=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.metadata.labels.role}')
if [ "$POD_LABEL" != "restricted" ]; then
  echo "❌ Pod '$POD_NAME' does not have label 'role=restricted' (got: $POD_LABEL)"
  exit 1
fi

# The default-deny egress policy must exist and include Egress
kubectl get networkpolicy "$POLICY_NAME" -n "$NAMESPACE" &> /dev/null || { echo "❌ NetworkPolicy '$POLICY_NAME' not found"; exit 1; }
POLICY_TYPES=$(kubectl get networkpolicy "$POLICY_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.policyTypes}')
if [[ "$POLICY_TYPES" != *"Egress"* ]]; then
  echo "❌ NetworkPolicy '$POLICY_NAME' does not include Egress in policyTypes"
  exit 1
fi

# It must apply to all pods in the namespace (empty podSelector) so restricted-pod is covered
POD_SELECTOR=$(kubectl get networkpolicy "$POLICY_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.podSelector.matchLabels}')
if [ -n "$POD_SELECTOR" ] && [ "$POD_SELECTOR" != "{}" ]; then
  echo "❌ NetworkPolicy '$POLICY_NAME' must select all pods (empty podSelector) to restrict non-admin pods (got: $POD_SELECTOR)"
  exit 1
fi

# The egress rule must exclude the API server IP via an 'except' block
API_SERVER_IP=$(kubectl get svc kubernetes -n default -o jsonpath='{.spec.clusterIP}')
EXCEPT_BLOCKS=$(kubectl get networkpolicy "$POLICY_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.egress[*].to[*].ipBlock.except}')
if [[ "$EXCEPT_BLOCKS" != *"$API_SERVER_IP"* ]]; then
  echo "❌ NetworkPolicy '$POLICY_NAME' does not exclude the API server IP ($API_SERVER_IP) from allowed egress"
  exit 1
fi

echo "✅ Restricted pod and api-server-policy are correctly configured to block API server egress for non-admin pods"
exit 0

#!/usr/bin/env bash
set -euo pipefail
# Safe bash mode: stop on error (-e), undefined vars (-u), pipe fails (-o pipefail).
# Some comments may contian little typos, code is untouched.

# Simulation flag: argument 1, default false
KV_ENABLED=${1:-false}

if [ "$KV_ENABLED" = "true" ]; then
  echo "Key Vault activé — exécution des commandes réelles (nécessite droits)."
  # In real mode, you need proper Azure login/identity.
  echo "Exemple: az login --identity"
  echo "az keyvault secret show --vault-name <NAME> --name db-password --query value -o tsv"
  exit 0
fi

# Simulation mode: local fallback
echo "=== MODE SIMULATION: récupération du secret depuis 'mock_secret.txt' ==="
if [ -f ./mock_secret.txt ]; then
  cat ./mock_secret.txt
else
  echo "SimulatedSecretValue123!"
  # Default fake secret if file not present
fi

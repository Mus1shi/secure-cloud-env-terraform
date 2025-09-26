#!/usr/bin/env bash
set -euo pipefail

# Simulation : on lit le "secret" depuis un fichier local si KeyVault disabled.
KV_ENABLED=${1:-false}

if [ "$KV_ENABLED" = "true" ]; then
  echo "Key Vault activé — exécution des commandes réelles (nécessite droits)."
  echo "Exemple: az login --identity"
  echo "az keyvault secret show --vault-name <NAME> --name db-password --query value -o tsv"
  exit 0
fi

# Simulation mode
echo "=== MODE SIMULATION: récupération du secret depuis 'mock_secret.txt' ==="
if [ -f ./mock_secret.txt ]; then
  cat ./mock_secret.txt
else
  echo "SimulatedSecretValue123!"
fi

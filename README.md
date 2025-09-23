Secure Cloud Environment on Azure with Terraform

Quick Description
This project provisions a structured, secure, and monitored Azure environment using Terraform.
It demonstrates Cloud Security best practices by combining network segmentation, a hardened bastion host, an isolated private VM, and a protected Key Vault.
The environment is integrated with Log Analytics and Azure Monitor, collecting logs, metrics, and generating alerts automatically.

1. Architecture Overview
Internet (your /32)
   │  SSH (22) allowed only from your IP
   ▼
[Bastion VM]  (public subnet 10.0.1.0/24, public IP)
   │  SSH ProxyJump only
   ▼
[Private VM] (private subnet 10.0.2.0/24, no public IP)
   │  Managed Identity + VNet service endpoint (KeyVault)
   ▼
[Azure Key Vault] (RBAC enabled, network ACL: only private subnet)


Security controls

Public NSG: Allow TCP/22 from my_ip_cidr only; deny everything else.

Private NSG: Allow TCP/22 only from the bastion subnet (10.0.1.0/24).

Key Vault: RBAC enabled, purge protection, soft delete, network ACL restricted to private subnet.

Private VM: Uses Managed Identity with roles Reader + Key Vault Secrets User.

2. Repository Layout
root/
  main.tf
  outputs.tf
  provider.tf
  terraform.tfvars (contains my_ip_cidr = "x.x.x.x/32")
  modules/
    network/
    compute/
    compute_private/
    keyvault/
    monitoring/

3. Prerequisites

Active Azure subscription + az login

Terraform ≥ 1.6

Sufficient permissions: create RG, VNet, NSG, VM, Key Vault, RBAC role assignments

Your public IP address (my_ip_cidr)

4. Deployment
terraform init -upgrade
terraform fmt -recursive
terraform apply -auto-approve


Expected outputs:

bastion_public_ip
private_vm_ip
keyvault_name
keyvault_uri

5. Testing & Validation

The environment has been tested and validated with the following scenarios:

🔹 Bastion Access
nc -vz $(terraform output -raw bastion_public_ip) 22
ssh -i .ssh/bastion_id_rsa azureuser@$(terraform output -raw bastion_public_ip)


👉 Bastion is reachable only from your IP.

🔹 Private VM via SSH Jump
ssh -o "ProxyCommand=ssh -i .ssh/bastion_id_rsa -W %h:%p azureuser@$(terraform output -raw bastion_public_ip)" \
    -i .ssh/private_vm_id_rsa \
    azureuser@$(terraform output -raw private_vm_ip)


👉 Private VM has no public exposure; access only through bastion.

🔹 Key Vault Access from Private VM
az login --identity
az keyvault secret show --vault-name $(terraform output -raw keyvault_name) \
  --name db-password --query value -o tsv


👉 Secret is retrieved only from within the private subnet via Managed Identity.

🔹 Monitoring & Alerts

Syslog events ingested from both VMs.

Azure Activity Logs streamed to Log Analytics.

Key Vault Audit Events visible.

CPU alerts automatically triggered above 80% usage for 5 minutes.

6. Monitoring & KQL Queries

All logs and metrics are centralized in the Log Analytics Workspace (LAW).
Below are ready-to-use KQL queries to validate and explore data.

🔹 Syslog – Authentication Events
Syslog
| where Facility in ("auth", "authpriv")
| where TimeGenerated > ago(1h)
| summarize count() by Computer, SeverityLevel, ProcessName

🔹 Syslog – Last 30 Minutes Summary
Syslog
| where TimeGenerated > ago(30m)
| summarize c = count() by Computer, Facility, SeverityLevel

🔹 Azure Activity – Subscription Operations
AzureActivity
| where TimeGenerated > ago(1d)
| project TimeGenerated, ResourceGroup, ResourceProvider, OperationName, Caller, ActivityStatus
| order by TimeGenerated desc

🔹 Key Vault – Access Audit
AzureDiagnostics
| where ResourceType == "VAULTS"
| where Category == "AuditEvent"
| project TimeGenerated, OperationName, ResultDescription, Identity
| order by TimeGenerated desc

🔹 VM CPU Utilization
InsightsMetrics
| where Namespace == "Processor"
| where Name == "UtilizationPercentage"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer
| order by TimeGenerated desc


How to run queries:

Go to Log Analytics Workspace → Logs in Azure Portal.

Select your workspace (law-secureenv).

Copy/paste a query.

Adjust time range if needed (ago(1h), ago(24h), etc.).

👉 Queries can be saved as Query Packs, transformed into custom alerts, or pinned into dashboards for visualization.

7. Security Measures

Network segmentation: strict separation between public/private.

Default-deny NSGs: only explicit flows allowed.

Just-in-time admin access: bastion limited to your /32.

Managed Identity: no secrets in code, access via RBAC.

Key Vault hardening: soft delete + purge protection.

Centralized monitoring: every critical component feeds into Log Analytics.

8. Operations & Cost Control

Update admin IP:

my_ip_cidr = "<NEW.IP>/32"
terraform apply -auto-approve


Lock down Key Vault after bootstrap:

network_acls { ip_rules = [] }


Destroy resources when done:

terraform destroy -auto-approve

9. Deliverable Checklist

[✔] Modular code (network, compute, keyvault, monitoring)

[✔] README with security explanations

[✔] Infrastructure tested and validated

[✔] KQL queries for log analysis

[✔] Screenshots: Azure resources, SSH jump, Key Vault access, Log Analytics results

[✔] Cleanup plan included

Example Outputs
bastion_admin_username = "azureuser"
bastion_private_key_path = "./.ssh/bastion_id_rsa"
bastion_public_ip = "4.180.237.185"
private_vm_admin_username = "azureuser"
private_vm_ip = "10.0.2.4"
private_vm_key_path = "./.ssh/private_vm_id_rsa"
keyvault_name = "kv-secureenv-xxxxxx"
keyvault_uri = "https://kv-secureenv-xxxxxx.vault.azure.net/"

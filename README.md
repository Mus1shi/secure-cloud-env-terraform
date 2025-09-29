# 🚀 Secure Cloud Environment on Azure (Terraform)

[![Terraform](https://img.shields.io/badge/IaC-Terraform-844fba?logo=terraform)]()
[![Azure](https://img.shields.io/badge/Cloud-Azure-0078D4?logo=microsoft-azure)]()
[![Security](https://img.shields.io/badge/Focus-Security-blue)]()

## 🔹 Quick Description
This project provisions a **structured, secure, and monitored Azure environment** using Terraform.  
It demonstrates Cloud Security best practices by combining:

- Network segmentation  
- Hardened bastion host  
- Isolated private VM  
- Protected Key Vault  
- Centralized monitoring (Log Analytics + Azure Monitor)

---

## 1. Architecture Overview
Internet (your /32)
│ SSH (22) allowed only from your IP
▼
[Bastion VM] (public subnet 10.0.1.0/24, public IP)
│ SSH ProxyJump only
▼
[Private VM] (private subnet 10.0.2.0/24, no public IP)
│ Managed Identity + VNet service endpoint (KeyVault)
▼
[Azure Key Vault] (RBAC enabled, network ACL: only private subnet)

markdown
Copier le code

### 🔐 Security controls
- **Public NSG** → Allow TCP/22 from `my_ip_cidr`, deny everything else  
- **Private NSG** → Allow TCP/22 only from bastion subnet (10.0.1.0/24)  
- **Key Vault** → RBAC enabled, purge protection, soft delete, private subnet only  
- **Private VM** → Managed Identity + `Reader` + `Key Vault Secrets User` roles  

---

## 2. Repository Layout
root/
main.tf
outputs.tf
provider.tf
terraform.tfvars # contains my_ip_cidr = "x.x.x.x/32"
modules/
network/
compute/
compute_private/
keyvault/
monitoring/
scripts/
demo_kv_read.sh # demo script to test Key Vault access (optional)

yaml
Copier le code

---

## 3. Prerequisites
- Active Azure subscription + `az login`
- Terraform ≥ 1.6
- Permissions: create RG, VNet, NSG, VM, Key Vault, RBAC roles
- Your **public IP address** (`my_ip_cidr`)

---
## 📸 Screenshots

### | Resource Group |

<img width="1880" height="1471" alt="image" src="https://github.com/user-attachments/assets/ecde69f4-6fe7-42a7-8f8d-aa4e49968933" />

<img width="1891" height="1522" alt="Capture d'écran 2025-09-29 082525" src="https://github.com/user-attachments/assets/d1202e3e-e58b-4a6e-a294-791ea4aa4375" />

<img width="1889" height="1501" alt="Capture d'écran 2025-09-29 082618" src="https://github.com/user-attachments/assets/794f9ad9-c9da-4a7e-9a3b-4e32d4d15199" />


### | VNet/Subnets |
<img width="1784" height="1198" alt="image" src="https://github.com/user-attachments/assets/8e8d9363-4f75-4e3d-ae42-5a8d3bc3474d" />

<img width="1729" height="1144" alt="image" src="https://github.com/user-attachments/assets/f3a7119c-a758-44d3-88bf-3bf0e6394067" />

### | Dashboard |

<img width="3060" height="1595" alt="image" src="https://github.com/user-attachments/assets/9390de47-fde4-4e04-be82-250bd952a39f" />


### | Bastion SSH |

<img width="1646" height="1238" alt="image" src="https://github.com/user-attachments/assets/7bc9686d-caee-486d-bbab-fc48efd2ffc4" />

### | Private VM |

<img width="1159" height="1136" alt="image" src="https://github.com/user-attachments/assets/6abc8c48-1ec0-4797-bf60-f159959e46ea" />


### | Log Analytics |

<img width="3006" height="1461" alt="image" src="https://github.com/user-attachments/assets/796688c4-10e0-4f53-ade8-78e8edfc16f8" />

---

## 4. Deployment

```bash
terraform init -upgrade
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply "tfplan"
✅ Expected outputs
bastion_public_ip

private_vm_ip

keyvault_name

keyvault_uri

5. Testing & Validation
🔹 Bastion Access
bash
Copier le code
nc -vz $(terraform output -raw bastion_public_ip) 22
ssh -i .ssh/bastion_id_rsa azureuser@$(terraform output -raw bastion_public_ip)
👉 Bastion is reachable only from your IP.

🔹 Private VM via SSH Jump
bash
Copier le code
ssh -J azureuser@$(terraform output -raw bastion_public_ip) \
    -i .ssh/private_vm_id_rsa \
    azureuser@$(terraform output -raw private_vm_ip)
👉 Private VM has no public exposure, accessible only through bastion.

🔹 Key Vault Access (if rights enabled)
bash
Copier le code
az login --identity
az keyvault secret show \
  --vault-name $(terraform output -raw keyvault_name) \
  --name db-password \
  --query value -o tsv
👉 Secret retrieved only inside private subnet via Managed Identity.

🔹 Monitoring & Alerts
Syslog events ingested from both VMs

Azure Activity Logs streamed to Log Analytics

Key Vault Audit Events visible

CPU alerts (triggered >80% usage for 5 min)

bash
Copier le code
# Check AMA agent
systemctl status azuremonitoragent

# Generate test logs
logger "test AMA from $(hostname) $(date)"

# Simulate high CPU load
sudo apt-get install -y stress-ng
stress-ng --cpu 2 --timeout 180
6. Monitoring & KQL Queries
All logs and metrics centralized in Log Analytics Workspace (LAW).

Example queries:
🔹 Syslog – Authentication Events

kql
Copier le code
Syslog
| where Facility in ("auth", "authpriv")
| where TimeGenerated > ago(1h)
| summarize count() by Computer, SeverityLevel, ProcessName
🔹 Azure Activity – Subscription Operations

kql
Copier le code
AzureActivity
| where TimeGenerated > ago(1d)
| project TimeGenerated, ResourceGroup, OperationName, Caller, ActivityStatus
| order by TimeGenerated desc
🔹 Key Vault – Access Audit

kql
Copier le code
AzureDiagnostics
| where ResourceType == "VAULTS"
| where Category == "AuditEvent"
| project TimeGenerated, OperationName, Identity, ResultDescription
🔹 CPU Utilization

kql
Copier le code
InsightsMetrics
| where Namespace == "Processor"
| where Name == "UtilizationPercentage"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer
👉 Queries can be saved, turned into alerts, or pinned to dashboards.

7. Security Measures
✅ Network segmentation → public vs private

✅ NSGs default-deny → allow only explicit flows

✅ Just-in-time access → bastion limited to your /32

✅ Managed Identity → no secrets in code

✅ Key Vault hardening → soft delete + purge protection

✅ Centralized monitoring → LAW + Alerts

8. Operations & Cost Control
Update admin IP:

hcl
Copier le code
my_ip_cidr = "<NEW_IP>/32"
bash
Copier le code
terraform apply -auto-approve
Destroy when done:

bash
Copier le code
terraform destroy -auto-approve
9. Deliverable Checklist
[✔] Modular Terraform code (network, compute, keyvault, monitoring)

[✔] README with security explanations

[✔] Infra tested and validated

[✔] Monitoring with KQL queries

[✔] Screenshots (to add)

[✔] Cleanup plan included

10. Example Outputs
bash
Copier le code
bastion_admin_username     = "azureuser"
bastion_private_key_path   = "./.ssh/bastion_id_rsa"
bastion_public_ip          = "172.201.13.196"
private_vm_admin_username  = "azureuser"
private_vm_ip              = "10.0.2.4"
private_vm_key_path        = "./.ssh/private_vm_id_rsa"
keyvault_name              = "(disabled)"
keyvault_uri               = "(disabled)"
📸 Screenshots (to add)
Azure Resource Group overview

VNet + Subnets diagram

Bastion SSH connection

Private VM via ProxyJump

AMA logs in Log Analytics

KQL queries results


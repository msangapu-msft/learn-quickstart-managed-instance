# Azure App Service Managed Instance Demo

This repository contains deployment scripts and infrastructure-as-code for provisioning an Azure App Service Managed Instance with custom font support.

## Overview

This project deploys an Azure App Service Managed Instance and supports packaging and uploading custom TrueType font (`.ttf`) files to Azure Blob Storage for later consumption.

## Running Environment

Intended to be executed in **Azure Cloud Shell** (Bash). Cloud Shell already includes:
- Azure CLI
- Azure Developer CLI (`azd`)
- OpenSSL
- jq
- unzip
- Bash

If you choose to run locally instead of Cloud Shell, you must ensure those tools are installed manually.

## Prerequisites

When using Azure Cloud Shell, the only prerequisites are:
- An Azure subscription where you can create resource groups, storage accounts, and managed identities.
- Permission to assign the “Storage Blob Data Contributor” role at the storage account scope (or have someone pre-assign it).
- A set of `.ttf` font files if you want font packaging to succeed.

## Project Structure

```
.
├── deploy.sh                  # Main deployment script
├── scripts/
│   └── prepare-install.sh     # Font packaging script
├── scripts.zip                # Generated during deployment
└── README.md
```

## Configuration

| Variable    | Default                | Description                          |
|-------------|------------------------|--------------------------------------|
| `ENV_NAME`  | `managed-instance-demo`| Azure Developer CLI environment name |
| `LOCATION`  | `northeurope`          | Azure region for deployment          |

Override on invocation:
```bash
ENV_NAME="my-env" LOCATION="eastus" ./deploy.sh
```

## Font Preparation

Place any `.ttf` font files in the location expected by `scripts/prepare-install.sh`. (Open the script to confirm the directory it zips—adjust if necessary.) Ensure it is executable:
```bash
chmod +x scripts/prepare-install.sh
```

## Deployment Instructions

### Quick Start (Cloud Shell)

```bash
git clone https://github.com/msangapu-msft/learn-quickstart-managed-instance.git
cd learn-quickstart-managed-instance
./deploy.sh
```

### Custom Deployment

```bash
ENV_NAME="my-custom-env" LOCATION="northeurope" ./deploy.sh
```

## Deployment Process

1. Cleans any existing azd environment directory (`.azure/$ENV_NAME`).
2. Creates (or reuses) a fixed resource group: `rg-managed-instance`.
3. Creates an azd environment; sets `AZURE_LOCATION` and `AZURE_RESOURCE_GROUP`.
4. Runs font packaging (`scripts/prepare-install.sh`) and validates `.ttf` presence.
5. Calls `azd provision` to create infrastructure (managed identity, storage account, container).
6. Assigns “Storage Blob Data Contributor” role to the signed-in user and waits ~20s.
7. Uploads `scripts.zip` to the provisioned storage container.

## Resources Created

- Resource Group: `rg-managed-instance`
- Storage Account (name comes from azd template)
- Storage Container
- Managed Identity
- Role Assignment: Storage Blob Data Contributor (current user)

## Post-Deployment

View environment values:
```bash
azd env get-values
```

You’ll see:
- `AZURE_RESOURCE_GROUP`
- `STORAGE_ACCOUNT_NAME`
- `STORAGE_CONTAINER_NAME`
- `MANAGED_IDENTITY_ID`

## Troubleshooting

### Font Package Issues
`ERROR: No fonts found in scripts.zip`
- Confirm `.ttf` files are placed correctly.
- Ensure `prepare-install.sh` is executable.
- Verify `unzip` output lists the fonts.

### Role / Upload Issues
- Confirm RBAC permissions for role assignment.
- If propagation delay persists, increase wait (e.g., 40–60s).
- Verify identity context: `az account show` and `az ad signed-in-user show`.

### Re-Running Deployments
Because the resource group name is fixed (`rg-managed-instance`), re-runs may reuse existing resources. For a clean run, delete the resource group first or modify the script to append a hash suffix.

## Clean Up

```bash
RG_NAME=$(azd env get-values --output json | jq -r .AZURE_RESOURCE_GROUP)
az group delete --name "$RG_NAME" --yes --no-wait
azd env delete --purge --force
```

## Optional Enhancements

If you want unique resource groups per run, update `deploy.sh`:
```bash
RANDOM_HASH=$(openssl rand -hex 4)
RG_NAME="rg-managed-instance-$RANDOM_HASH"
```

## Author

**msangapu-msft**  
Date: 2025-11-04

## License

[Add license information here]

## Contributing

[Add contribution guidelines if applicable]

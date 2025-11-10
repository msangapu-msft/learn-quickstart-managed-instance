# Azure App Service Managed Instance Demo

This repository contains deployment scripts and infrastructure-as-code for provisioning an Azure App Service Managed Instance with custom font support.

## Overview

This project deploys an Azure App Service Managed Instance in West Central US with custom font installation capabilities. The deployment includes:
- Azure Resource Group with random suffix for uniqueness
- Managed Identity for secure resource access
- Azure Storage Account for configuration packages
- Custom font installation support

## Prerequisites

Before running the deployment, ensure you have:

- **Azure CLI** installed and authenticated (`az login`)
- **Azure Developer CLI (azd)** installed
- **OpenSSL** for generating random hashes
- **jq** for JSON parsing
- **Bash shell** environment (Linux/macOS/WSL)
- Appropriate Azure subscription with permissions to create resources
- Storage Blob Data Contributor role assignment capability

## Project Structure

```
.
├── deploy.sh                    # Main deployment script
├── scripts/
│   └── prepare-install.sh       # Font package preparation script
├── scripts.zip    # Generated font package
└── README.md                    # This file
```

## Configuration

The deployment script uses the following environment variables (with defaults):

| Variable | Default | Description |
|----------|---------|-------------|
| `ENV_NAME` | `aptos-mi-demo` | Azure Developer CLI environment name |
| `LOCATION` | `northeurope` | Azure region for deployment |

## Deployment Instructions

### Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/msangapu-msft/learn-quickstart-managed-instance.git
   cd learn-quickstart-managed-instance
   ```

2. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

### Custom Deployment

To deploy with custom settings:

```bash
ENV_NAME="my-custom-env" LOCATION="northeurope" ./deploy.sh
```

## Deployment Process

The deployment script performs the following steps:

1. **Environment Setup**
   - Generates a random hash suffix for resource uniqueness
   - Creates resource group name: `rg-aptos-mi-demo-[hash]`
   - Cleans any existing environment configuration

2. **Resource Group Creation**
   - Creates a new Azure Resource Group in the specified location

3. **Azure Developer CLI Environment**
   - Creates a new azd environment
   - Sets Azure location and resource group variables

4. **Font Package Preparation**
   - Builds font installation package using `scripts/prepare-install.sh`
   - Verifies TTF fonts are properly packaged
   - Creates `scripts.zip` containing fonts

5. **Infrastructure Provisioning**
   - Provisions base infrastructure using azd
   - Creates:
     - Managed Identity
     - Storage Account
     - Storage Container

6. **Storage Configuration**
   - Grants current user Storage Blob Data Contributor role
   - Waits for role propagation (20 seconds)
   - Uploads font package to blob storage

## Resources Created

After successful deployment, the following Azure resources are created:

- **Resource Group**: `rg-aptos-mi-demo-[random-hash]`
- **Storage Account**: For configuration and font packages
- **Storage Container**: For storing installation scripts
- **Managed Identity**: For secure resource access
- **Role Assignments**: Storage Blob Data Contributor for deployment user

## Post-Deployment

After deployment completes, the script outputs:
- Resource Group name
- Storage Account name
- Storage Container name
- Managed Identity ID

These values are stored in the azd environment and can be retrieved using:
```bash
azd env get-values
```

## Troubleshooting

### Font Package Issues
If you encounter "No fonts found in scripts.zip":
- Ensure TTF font files are present in the expected location
- Check the `scripts/prepare-install.sh` script is executable
- Verify the font packaging process completes successfully

### Role Assignment Issues
If storage upload fails:
- Ensure you have permissions to assign roles in the subscription
- Wait additional time for role propagation if needed
- Check Azure AD permissions for the current user

### Clean Up

To remove all deployed resources:

```bash
# Get the resource group name
RG_NAME=$(azd env get-values --output json | jq -r .AZURE_RESOURCE_GROUP)

# Delete the resource group
az group delete --name "$RG_NAME" --yes --no-wait

# Remove the azd environment
azd env delete --purge --force
```

## Requirements

- Azure subscription with active credits/billing
- Azure CLI version 2.x or higher
- Azure Developer CLI (azd) latest version
- Bash shell (4.0+)
- OpenSSL
- jq (JSON processor)

## Author

**msangapu-msft**  
Date: 2025-11-04  
Location: West Central US

## License

[Add your license information here]

## Contributing

[Add contribution guidelines if applicable]
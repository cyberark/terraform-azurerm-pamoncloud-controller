#cloud-config
runcmd:
  - |
    # Update packages
    apt update -y

    # Install prerequisites
    apt install -y curl unzip jq

    # Install Python
    apt install -y python3-pip
    python3 --version

    # Install Python packages
    python3 -m pip install --upgrade "ansible==6.7.0" "ansible-core>=2.13.7" "pywinrm>=0.4.3"
    ansible --version

    # Install Packer
    export PACKER_VERSION="1.10.0"
    export PACKER_PACKAGE_NAME=$(printf "packer_%s_linux_amd64.zip" $PACKER_VERSION)
    curl -LO "https://releases.hashicorp.com/packer/$PACKER_VERSION/$PACKER_PACKAGE_NAME"
    unzip "$PACKER_PACKAGE_NAME" -d /usr/local/bin/
    rm -f "$PACKER_PACKAGE_NAME"
    packer version

    # Install Azure CLI
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    az --version

    # Authenticate to Azure using Managed Identity
    az login --identity

    # Download the BYOI ZIP file from Azure Storage Account
    az storage blob download --account-name "${storage_account_name}" --container-name "${container_name}" --name "${file_name}" --file "/home/${vm_admin_user}/${file_name}"

    # Unzip downloaded file and clean up
    cd /home/${vm_admin_user}
    unzip "${file_name}" -d PAMonCloud_BYOI
    rm -f "${file_name}"

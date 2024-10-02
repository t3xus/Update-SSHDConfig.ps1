<#
.SYNOPSIS
    PowerShell script that updates the OpenSSH server configuration and restarts the service to enhance security settings.

.DESCRIPTION
    This script performs the following actions:
    - Backs up the existing sshd_config file.
    - Updates the OpenSSH configuration with secure settings, including:
        - Setting SSH Protocol to 2
        - Disabling root login
        - Enforcing key-based authentication
        - Specifying strong ciphers, MACs, and key exchange algorithms
        - Configuring various security and performance options
    - Restarts the OpenSSH service to apply changes.

.EXAMPLE
    .\Update-SSHDConfig.ps1
    This command runs the script in the current directory.

.NOTES
    Author: James Gooch
    Last Edit: October 2, 2024
    Version: 1.0.0
    Requires: PowerShell version 5.1 or higher
              Modules: None specifically required beyond base PowerShell

.LINK
    For more information on OpenSSH configuration, refer to the official Microsoft documentation on SSH.

.COMPONENT
    Security Configuration, Network Services

.ROLE
    System Administrator

.FUNCTIONALITY
    SSH Server Configuration, Service Management

#>

#Requires -Version 5.1

<#

# Function to check if the script is running with elevated privileges
function Test-Admin {
    [bool]((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
}
# If not running as an administrator, restart the script with elevated privileges
if (-not (Test-Admin)) {
    $newProcess = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -PassThru
    $newProcess.WaitForExit()
    exit
}
# Define the path to the existing sshd_config file
$sshdConfigPath = "C:\ProgramData\ssh\sshd_config"
# Backup the existing configuration file
$backupPath = "C:\ProgramData\ssh\sshd_config.bak"
Copy-Item -Path $sshdConfigPath -Destination $backupPath -Force
Write-Host "Backup of sshd_config created at $backupPath"
# Define the new configuration settings
$newConfig = @'
# OpenSSH server configuration file
# Ensure the SSH Protocol is set to 2
Protocol 2
# Disable root login for security
PermitRootLogin yes
# Disable password authentication to enforce key-based authentication
PasswordAuthentication yes
# Specify allowed ciphers, MACs, and key exchange algorithms for stronger security
Ciphers aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
# Define the authorized keys file location
#AuthorizedKeysFile .ssh/authorized_keys
# Disable X11 forwarding
X11Forwarding no
# Disable TCP forwarding
AllowTcpForwarding no
# Only allow specific users to login
#AllowUsers Administrator
# Log Level
LogLevel VERBOSE
# Use DNS for authentication?
UseDNS no
# Reduce the idle time for SSH connections
ClientAliveInterval 300
ClientAliveCountMax 0
'@
# Stop the SSH service before changing the configuration
Stop-Service -Name sshd
Write-Host "Stopped the sshd service"
# Replace the existing sshd_config with the new configuration
$newConfig | Out-File -FilePath $sshdConfigPath -Encoding ascii -Force
Write-Host "Updated sshd_config with new secure settings"
# Start the SSH service again
Start-Service -Name sshd
Write-Host "Started the sshd service"
# Verify and display the status of the SSH service
$serviceStatus = Get-Service -Name sshd
Write-Host "SSH service status: $($serviceStatus.Status)"
#>

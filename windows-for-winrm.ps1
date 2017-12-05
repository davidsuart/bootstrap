<#
.Synopsis
  Configure WinRM over HTTPS
.DESCRIPTION
  Configure Windows with WinRM user-authenticated over https for [PSRemoting|WSMan|Ansible] management
.PARAMETER purge
  Use "-purge $false" to preserve any custom existing configuration. You probably do not want/need this.
.EXAMPLE
  ./windows-for-winrm.ps1 -purge $true
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Author: https://github.com/davidsuart
  Assumptions:
    - We are running on Windows OOTB or would like to reset the default configuration
    - We only want a single SSL listener and a self-signed certificate is acceptable
    - On the host firewall we want to permit WinRM-SSL access from any source
  Caveats:
    - The self-signed cert will have a CN of the local hostname which will fail CA/CN validation
    - To work with this you may need to use:
        - PowerShell:    PSSessionOption.SkipCACheck & PSSessionOption.SkipCNCheck
        - WSMan:         WSManFlagSkipCACheck & WSManFlagSkipCNCheck
        - Ansible:       ansible_winrm_server_cert_validation
  License: MIT License (See repository)
  Requires:
    - One of; Windows 8, 2012, 8.1, 2012 R2, 10, 2016
    - PowerShell v4.0 or greater (Required for native SelfSignedCertificate generation)
.LINK
  Repository: https://github.com/davidsuart/bootstrap
#>

# Parameters
param ( [Parameter(Mandatory=$false)] [bool]$purge=$true )

# Initialisation
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Functions
function configWinRM {
  begin {
    Write-Output "Configuring the WinRM service"
  }
  process {
    try {
        # Let PSRemoting/PSSessionConfiguration do the heavy lifting
        if ($purge)
        {
          # Register and enable the Microsoft.PowerShell/Microsoft.PowerShell32/Microsoft.PowerShell.Workflow session
          # .. configurations and change the security descriptor of all session configurations to allow remote access
          Enable-PSRemoting -SkipNetworkProfileCheck -Force | Out-Null
        }
        elseif (-not $purge)
        {
          # Ensure the Microsoft.PowerShell and Microsoft.PowerShell32 session configurations are enabled
          Enable-PSSessionConfiguration -Name "Microsoft.PowerShell", "Microsoft.PowerShell32" -Force | Out-Null
        }
        
        # Clean-out excess configuration from WSManQuickConfig and/or prior execution
        if ($purge)
        {
          # Remove any non-SSL listener(s) which Set-WSManQuickConfig creates by default
          Get-ChildItem WSMan:\Localhost\listener | Where -Property Keys -eq "Transport=HTTP" | Remove-Item -Recurse
        
          # .. and SSL based listeners in case we are re-running or cleaning up a broken configuration
          Get-ChildItem WSMan:\Localhost\listener | Where -Property Keys -eq "Transport=HTTPS" | Remove-Item -Recurse
        
          # Disable the non-SSL WinRM firewall rules
          Get-NetFirewallRule | ? {$_.Name -match "WINRM-HTTP-*"} | Set-NetFirewallRule -Enabled "False"
        
          # Remove our custom WinRM-SSL firewall rule if present
          Get-NetFirewallRule | ? {$_.Name -match "WINRM-HTTPS-In-TCP"} | Remove-NetFirewallRule
        
          Write-Output "Removed existing listeners and disabled default firewall rules"
        }
        elseif (-not $purge)
        {
          Write-Output "Not removing any existing listeners/firewall rules due to [-purge `$false] flag"
        }
        
        # Note: Temporarily disable subject to further testing
        # Restrict unencrypted communication on the service
        # Set-Item WSMan:\localhost\Service\AllowUnencrypted -value false

        # Enable basic and negotiate auth on the server
        Set-Item -Path "WSMan:\localhost\Service\Auth\Basic" -Value $true
        Set-Item -Path "WSMan:\localhost\Service\Auth\Negotiate" -Value $true

        # Note: Temporarily disable subject to further testing
        # Increase timeout to 15 min
        # Set-Item -Path "WSMan:\localhost\MaxTimeoutms" 900000

        # Increase memory allocated to shell sessions
        Set-Item -Path "WSMan:\localhost\Shell\MaxMemoryPerShellMB" 1024 -WarningAction SilentlyContinue
        Set-Item -Path "WSMan:\localhost\Plugin\Microsoft.PowerShell\Quotas\MaxMemoryPerShellMB" 1024 `
          -WarningAction SilentlyContinue
        Set-Item -Path "WSMan:\localhost\Plugin\Microsoft.PowerShell32\Quotas\MaxMemoryPerShellMB" 1024 `
          -WarningAction SilentlyContinue

        # Make sure WinRM is set to auto-start
        Set-Service -Name "WinRM" -StartupType Automatic

        # Configure LocalAccountTokenFilterPolicy to grant administrative rights remotely to local users.
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
          -Name LocalAccountTokenFilterPolicy -Value 1

        # Enable the PowerShell WSMan providers
        Set-Item -Path "WSMan:\localhost\Plugin\Microsoft.PowerShell\Enabled" true -WarningAction SilentlyContinue
        Set-Item -Path "WSMan:\localhost\Plugin\Microsoft.PowerShell32\Enabled" true -WarningAction SilentlyContinue

        # Get the hostname
        Set-Variable -Name "strHostName" -Value `
        ([System.Net.Dns]::GetHostByName((hostname)).HostName).ToLower()
        
        # Create a self-signed cert to secure the WinRM endpoint
        Set-Variable -Name "WinRMCert" -Value `
          (New-SelfSignedCertificate -CertStoreLocation "cert:\LocalMachine\My" -DnsName "$strHostName")
        Write-Output "Created a Self Signed Certificate for [$strHostName]"
        
        # Create a listener using the new cert
        New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $WinRMCert.Thumbprint `
          –Force | Out-Null
        Write-Output "Created a WinRM HTTPS listener"
        
        if ( ($purge) -or !(Get-NetFirewallRule -Name "WINRM-HTTPS-In-TCP" 2> $null) )
        {
          # Create our own firewall rule for WinRM/SSL
          New-NetFirewallRule -Name "WINRM-HTTPS-In-TCP" -DisplayName "Permit Windows Remote Management (HTTPS-In)" -Direction `
            Inbound -Action Allow -EdgeTraversalPolicy Allow -Protocol TCP -LocalPort 5986 -Profile Any -Enabled True | Out-Null
          Write-Output "Created a Windows Firewall rule for WinRM-HTTPS"
        }
        elseif (-not $purge)
        {
          # Enable the rule already present
          Get-NetFirewallRule | ? {$_.Name -match "WINRM-HTTPS-In-TCP"} | Set-NetFirewallRule -Enabled "True"
          Write-Output "Enabled the Windows Firewall rule for WinRM-HTTPS"
        }
        
        # Restart the WinRM service
        Write-Output "Restarting the WinRM service"
        Restart-Service -Name "WinRM" -ErrorAction Stop
        }
    catch {
      Write-Host $_.Exception.Message -ForegroundColor Yellow
      break
    }
  }
  end {
    if ($?) {
      Write-Output "Completed."
    }
  }
}

# Execution
if ( [Environment]::OSVersion.Version -lt (new-object 'Version' 6,2) )
{
  Write-Warning "This script is only compatible with Windows 8/Server 2012 or newer."
  return "Unable to continue."
}
elseif ( $PSVersionTable.PSVersion.Major -lt 4 )
{
  Write-Warning "This script requires at least PowerShell v4.0"
  return "Unable to continue."
}
else
{
  configWinRM
}

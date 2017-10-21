<#
.Synopsis
  Enable Remote Desktop
.DESCRIPTION
  Configure Windows to enable Remote Desktop from any origin
.EXAMPLE
  ./enable-windows-rdp.ps1
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Author: https://github.com/davidsuart
  Assumptions:
    - On the host firewall we want to permit Remote Desktop access from any source
  Caveats:
    - Re-uses Windows Server default firewall rules/names
  License: MIT License (See repository)
  Requires:
    - One of; Windows 7, 2008 R2, 8, 2012, 8.1, 2012 R2, 10, 2016
.LINK
  Repository: https://github.com/davidsuart/bootstrap
#>

# Initialisation
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function configWinRDP {
  begin {
    Write-Output "Configuring Remote Desktop"
  }
  process {
    try {
      # Enable Terminal Server connections
      Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
    
      # Enable the inbuilt TCP-based RDP firewall rule
      if ($PSVersionTable.PSVersion.Major -gt 2)
      {
        Enable-NetFirewallRule -Name "RemoteDesktop-UserMode-In-TCP"
      }
      else
      {
        # Fall back to netsh for circa Windows Server 2008 R2 RTM/OOTB
        netsh advfirewall firewall set rule name="Remote Desktop (TCP-In)" new enable=yes
      }  
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
if ( [Environment]::OSVersion.Version -lt (new-object 'Version' 6,1) )
{
  Write-Warning "This script is only compatible with Windows 7/Server 2008 R2 or newer."
  return "Unable to continue."
}
elseif ( $PSVersionTable.PSVersion.Major -lt 1 )
{
  Write-Warning "This script requires at least PowerShell v1.0"
  return "Unable to continue."
}
else
{
  configWinRDP
}


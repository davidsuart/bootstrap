#
# [ABOUT]
# - Configure Windows to enable Remote Desktop
#
# [ASSUMPTIONS]
# - We will permit RDP access from all sources on the host firewall
#
# [CAVEATS]
# - Re-uses Windows Server default firewall rules/names
#

try
{
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
catch
{
  Write-Host $_.Exception.Message -ForegroundColor Yellow
  Break
}

#Connect to Azure Automation
$Credentials = Get-AutomationPSCredential -Name 'Office 365 SubX'
 
# Function: Connect to Exchange Online 
function Connect-ExchangeOnline {
    param (
        $Creds
    )
        Write-Output "Connecting to Exchange Online"
        Get-PSSession | Remove-PSSession       
        $Session = New-PSSession –ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Creds -Authentication Basic -AllowRedirection
        $Commands = @("Get-MailboxFolderPermission","Set-MailboxFolderPermission","Set-Mailbox","Get-Mailbox","Set-CalendarProcessing","Add-DistributionGroupMember")
        Import-PSSession -Session $Session -DisableNameChecking:$true -AllowClobber:$true -CommandName $Commands | Out-Null
    }
 
# Connect to Exchange Online
Connect-ExchangeOnline -Creds $Credentials
 
# Enable Mailbox Audit for All Users
Write-Output "Enable Mailbox Audit for all Users"
Get-Mailbox -Filter {RecipientTypeDetails -eq "UserMailbox" -and AuditEnabled -eq $False} | Set-Mailbox -AuditEnabled $True
 
# Set AuditLogAgeLimit to 1 year
Write-Output "Set Mailbox Audit Log Age Limit for all Users"
Get-Mailbox -Filter {RecipientTypeDetails -eq "UserMailbox"} | Set-Mailbox -AuditLogAgeLimit 365
 
# Close Session
Get-PSSession | Remove-PSSession
 
Write-Output "Script Completed!"
Get-PSSession | Remove-PSSession

# Connect to Office 365
$Credentials = Get-AutomationPSCredential -Name "Office 365"
Connect-MsolService -Credential $Credentials

# Function: Connect to Exchange Online 
function Connect-ExchangeOnline {
    param (
        $Creds
    )
        Write-Output "Connecting to Exchange Online"
        Get-PSSession | Remove-PSSession       
        $Session = New-PSSession –ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Creds -Authentication Basic -AllowRedirection
        $Commands = @("Get-MailboxFolderPermission","Set-MailboxFolderPermission","Set-Mailbox","Get-Mailbox","Set-CalendarProcessing","Add-DistributionGroupMember")
        Import-PSSession -Session $Session -DisableNameChecking:$true -AllowClobber:$true | Out-Null
        Connect-MsolService -Credential $Creds
    }
 
# Connect to Exchange Online
Connect-ExchangeOnline -Creds $Credentials


# Block Inbox Rules from forwarding mail externally in your own Office 365 tenant.

#Setting variables
$externalTransportRuleName = "Inbox Rules To External Block"
$rejectMessageText = "To improve security, auto-forwarding rules to external addresses has been disabled. Please contact your company administrator if you'd like to set up an exception."
 
$externalForwardRule = Get-TransportRule | Where-Object {$_.Identity -contains $externalTransportRuleName}
 
if (!$externalForwardRule) {
    Write-Output "Client Rules To External Block not found, creating Rule"
    New-TransportRule -name "Client Rules To External Block" -Priority 1 -SentToScope NotInOrganization -FromScope InOrganization -MessageTypeMatches AutoForward -RejectMessageEnhancedStatusCode 5.7.1 -RejectMessageReasonText $rejectMessageText
}  
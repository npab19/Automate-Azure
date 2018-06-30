Param
(
  [Parameter (Mandatory= $true)]
  [Type] $Name1 = <Default value>,

  [Parameter (Mandatory= $true)]
  [Type] $Name2 = <Default value>
)



Get-PSSession | Remove-PSSession
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
        Import-PSSession -Session $Session -DisableNameChecking:$true -AllowClobber:$true | Out-Null
        Connect-MsolService -Credential $Creds
    }
 
# Connect to Exchange Online
Connect-ExchangeOnline -Creds $Credentials

$allUsers = @()
$AllUsers = Get-MsolUser -All -EnabledFilter EnabledOnly | select ObjectID, UserPrincipalName, FirstName, LastName, StrongAuthenticationRequirements, StsRefreshTokensValidFrom, StrongPasswordRequired, LastPasswordChangeTimestamp | Where-Object {($_.UserPrincipalName -notlike "*#EXT#*")}
$UserDelegates = @()
foreach ($User in $allUsers)
{
    Write-Host "Checking inbox rules and delegates for user: " $User.UserPrincipalName;
    $UserInboxRules += Get-InboxRule -Mailbox $User.UserPrincipalname | Select Name, Description, Enabled, Priority, ForwardTo, ForwardAsAttachmentTo, RedirectTo, DeleteMessage | Where-Object {($_.ForwardTo -ne $null) -or ($_.ForwardAsAttachmentTo -ne $null) -or ($_.RedirectsTo -ne $null)}
    $UserDelegates += Get-MailboxPermission -Identity $User.UserPrincipalName | Where-Object {($_.IsInherited -ne "True") -and ($_.User -notlike "*SELF*")}
}

$UserInboxRules | Export-Csv MailForwardingRulesToExternalDomains.csv
$UserDelegates | Export-Csv MailboxDelegatePermissions.csv

# Sets varabiles for outgoing email
$emailFromAddress = "it@subx.co"
$emailToAddress = "nikko.pabion@wheelhouseit.com"
$emailSMTPServer = "outlook.office365.com"
$emailSubject = "Office 365 License Report"

# Sends email to user listed in $emailToAddress
Send-MailMessage -Credential $Credentials -From $emailFromAddress -To $emailToAddress -Subject $emailSubject -Body "Attached is a report of all mailbox SMTP fowarding set at exchange" -SmtpServer $emailSMTPServer -UseSSL -Attachments "MailboxDelegatePermissions.csv"

# Deleats file
rm "MailForwardingRulesToExternalDomains.csv"
rm "MailboxDelegatePermissions.csv"

# Remove PS Session
Get-PSSession | Remove-PSSession

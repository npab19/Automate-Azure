Get-PSSession | Remove-PSSession

# Connect to Azure Automation
$Credentials = Get-AutomationPSCredential -Name "Office 365"

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

# Create new distribution group if non exist
if (get-distributiongroup O365_notification)
    {
    Write-Host "Group Exist"
    }
    
else 
    {
    Write-Host "Group Does Not Exist"
    New-DistributionGroup -Name "O365_notification" -Type "Security"
    #$Global_Admins = Get-MsolRole -RoleName "Company Administrator"
    #Get-MsolRoleMember -RoleObjectId $Global_Admins.ObjectId | ForEach-object {
    #    Add-DistributionGroupMember -Identity O365_notification -Member $_.EmailAddress
    #    }
    }





# Created the required varbiables
$NotificationEmail = Get-DistributionGroup -identity o365_notification

# Edits the default outbound spam policy.
Set-HostedOutboundSpamFilterPolicy Default -NotifyOutboundSpam $true -NotifyOutboundSpamRecipients $NotificationEmail.PrimarySmtpAddress
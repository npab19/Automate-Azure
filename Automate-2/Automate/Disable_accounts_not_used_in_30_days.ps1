# Remove all existing Powershell sessions 
Get-PSSession | Remove-PSSession

# Connect to Azure Automation
$Credentials = Get-AutomationPSCredential -Name 'Office 365 SubX'

# Function: Connect to Exchange Online 
function Connect-ExchangeOnline {
    param (
        $Creds
    )
        Write-Output "Connecting to Exchange Online"
        Get-PSSession | Remove-PSSession       
        $Session = New-PSSession –ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Creds -Authentication Basic -AllowRedirection
        #$Commands = @("Get-MailboxFolderPermission","Set-MailboxFolderPermission","Set-Mailbox","Get-Mailbox","Set-CalendarProcessing","Add-DistributionGroupMember")
        Import-PSSession -Session $Session -DisableNameChecking:$true -AllowClobber:$true | Out-Null
        Connect-MsolService -Credential $Creds
    }
 
# Connect to Exchange Online
Connect-ExchangeOnline -Creds $Credentials

    
{ 
    #No input file found, gather all mailboxes from Office 365 
    $objUsers = get-mailbox -ResultSize Unlimited | select UserPrincipalName 
} 
    
#Iterate through all users     
Foreach ($objUser in $objUsers) 
{     
    #Connect to the users mailbox 
    $objUserMailbox = get-mailboxstatistics -Identity $($objUser.UserPrincipalName) | Select LastLogonTime 
        
    #Prepare UserPrincipalName variable 
    $strUserPrincipalName = $objUser.UserPrincipalName 
        
    #Check if they have a last logon time. Users who have never logged in do not have this property 
    if ($objUserMailbox.LastLogonTime -eq $null) 
    { 
        #Never logged in, update Last Logon Variable 
        $strLastLogonTime = "Never Logged In" 
    } 
    else 
    { 
        #Update last logon variable with data from Office 365 
        $strLastLogonTime = $objUserMailbox.LastLogonTime 
    } 
        
    #Output result to screen for debuging (Uncomment to use) 
    #write-host "$strUserPrincipalName : $strLastLogonTime" 
        
    #Prepare the user details in CSV format for writing to file 
    $strUserDetails = "$strUserPrincipalName,$strLastLogonTime" 
        
    #Append the data to file 
    Out-File -FilePath $OutputFile -InputObject $strUserDetails -Encoding UTF8 -append 
} 
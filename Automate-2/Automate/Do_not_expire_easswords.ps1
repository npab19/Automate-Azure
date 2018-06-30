Get-PSSession | Remove-PSSession
# Connect to Office 365
$Credentials = Get-AutomationPSCredential -Name 'Office 365 Subx 3'
Connect-MsolService -Credential $Credentials

# Get all verifed domains
$domains = Get-MsolDomain | Where-Object {$_.Status -eq "Verified"}
 
 # Set password policy for all domains
foreach($domain in $domains)
    {
    $domainStatus = Get-MsolPasswordPolicy -DomainName $domain.Name
    Write-Output = $domainStatus
    if($domainStatus.ValidityPeriod -ne 2147483647){
    Write-Output "Setting the Password Expiration Policy on $($domain.Name)"
    Set-MsolPasswordPolicy -DomainName $domain.Name -ValidityPeriod 2147483647 -NotificationDays 30}
    }

# Sets password to never expire for all users
Get-MSOLUser | Set-MsolUser -PasswordNeverExpires $true

# Outputs all users password policy
$VerifyPassword = Get-MSOLUser | Select UserPrincipalName, PasswordNeverExpires
Write-Output $VerifyPassword

Get-PSSession | Remove-PSSession
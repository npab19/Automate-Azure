$ClientID       = Get-AutomationVariable -Name 'AzureAdClientID'      # Should be a ~36 hex character string; insert your info here
$ClientSecret   = Get-AutomationVariable -Name 'ClientSecret'    # Should be a ~44 character string; insert your info here
$tenantdomain   = "4cornerit.onmicrosoft.com"    # For example, contoso.onmicrosoft.com

$loginURL       = "https://login.microsoft.com"
$resource       = "https://graph.microsoft.com"

$body       = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}
$oauth      = Invoke-RestMethod -Method Post -Uri $loginURL/$tenantdomain/oauth2/token?api-version=1.0 -Body $body

#Write-Output $oauth

if ($oauth.access_token -ne $null) {
    $headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}

    $url = "https://graph.microsoft.com/beta/identityRiskEvents"
    #Write-Output $url

    $myReport = (Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url)

    foreach ($event in ($myReport.Content | ConvertFrom-Json).value) {
        $RiskySignIn = $Event
        Write-Output $Event
    }

} else {
    Write-Host "ERROR: No Access Token"
} 

# Remove PS Session
Get-PSSession | Remove-PSSession
#Connect to Azure Automation
$Credentials = Get-AutomationPSCredential -Name 'Office 365 CSP Admin account'

# Puts all gathered data into a CSV
$RiskySignIn | Export-Csv "Risky Sign In.csv"

# Sets varabiles for outgoing email
$emailFromAddress = "cspadmin@wheelhouseit.com"
$emailToAddress = "nikko.pabion@wheelhouseit.com"
$emailSMTPServer = "outlook.office365.com"
$emailSubject = "Azure AD Risky Sign In Report"

# Sends email to user listed in $emailToAddress
Send-MailMessage -Credential $Credentials -From $emailFromAddress -To $emailToAddress -Subject $emailSubject -Body "Attached is a report of all mailbox SMTP fowarding set at exchange" -SmtpServer $emailSMTPServer -UseSSL -Attachments "Risky Sign In.csv"

# Deleats file
rm "Risky Sign In.csv"

# Remove PS Session
Get-PSSession | Remove-PSSession

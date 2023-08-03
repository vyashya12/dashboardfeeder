Set-Location \
# Set String
New-Item -ItemType Directory -Name SecureString
Get-Credential -Credential (Get-Credential) | Export-Clixml "C:\SecureString\SecureCredentials.xml"

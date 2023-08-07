# URL to the PsExec download page
$psExecUrl = "https://download.sysinternals.com/files/PSTools.zip"

# Path to the directory where you want to save the downloaded files
$downloadPath = "C:SecureString\"

# Create the download directory if it doesn't exist
if (-not (Test-Path -Path $downloadPath)) {
    New-Item -Path $downloadPath -ItemType Directory
}

# Combine the download path with the filename
$psExecZipPath = Join-Path -Path $downloadPath -ChildPath "PSTools.zip"

# Download the PsExec zip file
Invoke-WebRequest -Uri $psExecUrl -OutFile $psExecZipPath

# Expand the downloaded zip file
Expand-Archive -Path $psExecZipPath -DestinationPath $downloadPath

# Remove the zip file after extracting
Remove-Item -Path $psExecZipPath -Force

Get-Credential -Credential (Get-Credential) | Export-Clixml "C:\SecureString\SecureCredentials.xml"
# Import File
#$Credentials = IMPORT-CLIXML "C:\SecureString\SecureCredentials.xml"
#$RESTAPIUser = $Credentials.UserName
# $RESTAPIPassword = $Credentials.GetNetworkCredential().Password
#$apicred = (New-Object PSCredential â€œserver_userâ€,$Credentials.password).GetNetworkCredential().Password

# Get the server hostname
$hostname = (Get-WmiObject Win32_ComputerSystem).Name
#$outputFilePath = "C:\exabytes\script\$hostname.csv"
$ip = (Test-Connection -ComputerName (hostname) -Count 1).IPV4Address.IPAddressToString

$os = Get-WmiObject -Class Win32_OperatingSystem
$uptime = (Get-Date) - ($os.ConvertToDateTime($os.LastBootUpTime))

#$onlineVMCount = (Get-VM | Where { $_.State -eq 'Running' }).Count
#$offlineVMCount = (Get-VM | Where { $_.State -eq 'Off' }).Count

$username = "server_user"
$password = "g1paGwcmEYsVlQEKNyfgFwqvj"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

$os = Get-WmiObject Win32_OperatingSystem
$totalMemoryGB = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeMemoryGB = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedMemoryGB = [Math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)

$time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Get the free disk space for C and D drives
$partitions = Get-WmiObject -Class Win32_Volume -Filter "DriveType = 3 AND (DriveLetter = 'C:' OR DriveLetter = 'D:')" | ForEach-Object {
    $sizeGB = "{0:N2}" -f ($_.Capacity / 1GB)
    $freeGB = "{0:N2}" -f ($_.FreeSpace / 1GB)
    $usedGB = "{0:N2}" -f (($_.Capacity - $_.FreeSpace) / 1GB)
    

# Initialize empty lists to store drive information
$DriveLetters = @()
$RemainingSpace = @()
$UsedSpace = @()
$TotalSpace = @()

# Get drive information using WMI
$drives = Get-WmiObject -Class Win32_LogicalDisk

# Loop through each drive and populate the lists
foreach ($drive in $drives) {
    # Get drive letter
    $DriveLetter = $drive.DeviceID

    # Get remaining space in bytes
    $RemainingSpaceBytes = [double]$drive.FreeSpace

    # Get used space in bytes
    $UsedSpaceBytes = [double]($drive.Size - $drive.FreeSpace)

    # Get total space in bytes
    $TotalSpaceBytes = [double]$drive.Size

    # Convert bytes to human-readable sizes (MB)
    $RemainingSpaceMB = [math]::Round($RemainingSpaceBytes / 1GB, 2)
    $UsedSpaceMB = [math]::Round($UsedSpaceBytes / 1GB, 2)
    $TotalSpaceMB = [math]::Round($TotalSpaceBytes / 1GB, 2)

    # Add drive information to lists
    $DriveLetters += $DriveLetter
    $RemainingSpace += $RemainingSpaceMB
    $UsedSpace += $UsedSpaceMB
    $TotalSpace += $TotalSpaceMB
}

# Display the collected information (optional)
$allLetters = ""
$allRemaining = ""
$allUsed = ""
$allTotal = ""
$allPercentage = ""

for ($i = 0; $i -lt $DriveLetters.Count; $i++) {
    $allLetters += "$($DriveLetters[$i]), "
    $allRemaining += "$($RemainingSpace[$i]) GB, "
    $allUsed += "$($UsedSpace[$i]) GB, "
    $allTotal += "$($TotalSpace[$i]) GB, "
    $onePercentage = $RemainingSpace[$i] / $TotalSpace[$i] * 100
    $allPercentage += "$($onePercentage.ToString("F2"))%, "
}

    [PSCustomObject]@{
        ServerName = $hostname
        IP = $ip
        DriveLetter = $allLetters
        Size = $sizeGB
        Free = $freeGB
        Used = $usedGB
        PercentFree = $allPercentage
        OnlineVPS = 0
        OfflineVPS = 0
        UsedMemory = $allUsed
        FreeMemory = $allRemaining
        TotalMemory = $allTotal
        LastUpdate = $time
        ServerUptime = $uptime.Days
        APIPassword = $apicred
    }
}

# Building body to send via http
$body = @{
    "APIUser" = $credential.GetNetworkCredential().Username
    "APIPassword" = $credential.GetNetworkCredential().Password
    "ServerName" = $hostname
    "IP" = $ip
    "Drive" = $allLetters
    "Size" = $sizeGB
    "SizeFree" = $freeGB
    "SizeUsed" = $usedGB
    "PercentFree" = $allPercentage
    "TotalMemory" = $allTotal
    "FreeMemory" = $allRemaining    
    "UsedMemory" = $allUsed
    "OnlineVPS" = 0
    "OfflineVPS" = 0
    "LastUpdate" = $time
    "ServerUptime" = $uptime.Days
}

# Needs to be converted to JSON
$JsonBody = $body | ConvertTo-Json

# API call paramaters(Required*)
$Params = @{
    Method = 'Post'
    Uri = 'https://hub.vyashya.com/api/servers/add'
    Body = $JsonBody
    ContentType = 'application/json'
}

# Sending by http
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-RestMethod @Params

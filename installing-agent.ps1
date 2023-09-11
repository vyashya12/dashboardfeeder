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

#$onlineVMCount = (Get-VM | Where { $_.State -eq Running }).Count
#$offlineVMCount = (Get-VM | Where { $_.State -eq Off }).Count

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
    $driveLetter = $_.DriveLetter
    $sizeGB = "{0:N2}" -f ($_.Capacity / 1GB)
    $freeGB = "{0:N2}" -f ($_.FreeSpace / 1GB)
    $usedGB = "{0:N2}" -f (($_.Capacity - $_.FreeSpace) / 1GB)
    if ($_.Capacity -gt 0) {
        $percentFree = "{0:N2}%" -f ($_.FreeSpace / $_.Capacity * 100)
    } else {
        $percentFree = "N/A"
    }

    [PSCustomObject]@{
        ServerName = $hostname
        IP = $ip
        DriveLetter = $driveLetter
        Size = $sizeGB
        Free = $freeGB
        Used = $usedGB
        PercentFree = $percentFree
        OnlineVPS = 0
        OfflineVPS = 0
        UsedMemory = $usedMemoryGB
        FreeMemory = $freeMemoryGB
        TotalMemory = $totalMemoryGB
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
    "Drive" = $driveLetter
    "Size" = $sizeGB
    "SizeFree" = $freeGB
    "SizeUsed" = $usedGB
    "PercentFree" = $percentFree
    "TotalMemory" = $totalMemoryGB
    "FreeMemory" = $freeMemoryGB    
    "UsedMemory" = $usedMemoryGB
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

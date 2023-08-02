# Import File
$Credentials = IMPORT-CLIXML "C:\SecureString\SecureCredentials.xml"

# Get the server hostname
$hostname = (Get-WmiObject Win32_ComputerSystem).Name
#$outputFilePath = "C:\exabytes\script\$hostname.csv"
$ip = (Test-Connection -ComputerName (hostname) -Count 1).IPV4Address.IPAddressToString

$os = Get-WmiObject -Class Win32_OperatingSystem
$uptime = (Get-Date) - ($os.ConvertToDateTime($os.LastBootUpTime))

#$onlineVMCount = (Get-VM | Where { $_.State -eq Running }).Count
#$offlineVMCount = (Get-VM | Where { $_.State -eq Off }).Count

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
        OnlineVPS = $onlineVMCount
        OfflineVPS = $offlineVMCount
        UsedMemory = $usedMemoryGB
        FreeMemory = $freeMemoryGB
        TotalMemory = $totalMemoryGB
        LastUpdate = $time
        ServerUptime = $uptime.Days
        
    }
}

# Retrieve Important Strings
$RESTAPIUser = $Credentials.UserName
$RESTAPIPassword = $Credentials.GetNetworkCredential().Password

# Building body to send via http
$body = @{
    "APIPassword" = "g1paGwcmEYsVlQEKNyfgFwqvj"
    "ServerName"= "CoolServer"
    "IP"= "127.0.0.1.00"
    "Drive"= "V"
    "Size"= "30"
    "SizeFree"= "31.40"
    "SizeUsed"= "43.20"
    "PercentFree"= "42"
    "TotalMemory"= "7.78"
    "FreeMemory"= "2.2"   
    "UsedMemory"= "5.6"
    "OnlineVPS"= "3"
    "OfflineVPS"= "2"
    "LastUpdate"= "1212"
    "ServerUptime"= "29"
}

# Needs to be converted to JSON
$JsonBody = $body | ConvertTo-Json

# API call paramaters(Required*)
$Params = @{
    Method = 'Post'
    Uri = 'https://api.vyashya.com/api/servers/'
    Body = $JsonBody
    ContentType = 'application/json'
}

# Sending by http
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-RestMethod @Params

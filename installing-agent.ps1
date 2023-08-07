# Import File
#$Credentials = IMPORT-CLIXML "C:\SecureString\SecureCredentials.xml"
#$RESTAPIUser = $Credentials.UserName
# $RESTAPIPassword = $Credentials.GetNetworkCredential().Password
#$apicred = (New-Object PSCredential “server_user”,$Credentials.password).GetNetworkCredential().Password

# Get the server hostname
$hostname = (Get-WmiObject Win32_ComputerSystem).Name
#$outputFilePath = "C:\exabytes\script\$hostname.csv"
$ip = (Test-Connection -ComputerName (hostname) -Count 1).IPV4Address.IPAddressToString

$os = Get-WmiObject -Class Win32_OperatingSystem
$uptime = (Get-Date) - ($os.ConvertToDateTime($os.LastBootUpTime))

#$onlineVMCount = (Get-VM | Where { $_.State -eq Running }).Count
#$offlineVMCount = (Get-VM | Where { $_.State -eq Off }).Count

$username = "server_user"
$password = "16ef4c840068267820ccdce99c9b05b6079ca413b9e1d7982b15684034467729"
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
        OnlineVPS = $onlineVMCount
        OfflineVPS = $offlineVMCount
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
    "APIUser" = $username
    "APIPassword" = $password
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
    "OnlineVPS" = $onlineVMCount
    "OfflineVPS" = $offlineVMCount
    "LastUpdate" = $time
    "ServerUptime" = $uptime.Days
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

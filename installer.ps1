$taskName = "Dashboard-Collector"
$taskNameString = "Important-String-Creation"
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
$task2 = Get-ScheduledTask -TaskName $taskNameString -ErrorAction SilentlyContinue

if ($task -ne $null) {
    #Write-Host "The scheduled task $taskName exists."
}
else {
    Set-Location \
    # Set String
    New-Item -ItemType Directory -Name SecureString
    $githubURL = "https://raw.githubusercontent.com/vyashya12/dashboardfeeder/main/test.ps1"
    $localXmlPath = "C:\task.xml"
    
    Invoke-RestMethod -Uri $githubURL -OutFile $localXmlPath
    # Install scheduled task to create important string user SYSTEM
    # Register-ScheduledTask -TaskName $taskNameString -Xml $fileContentString -Force -User "SYSTEM" -RunLevel Highest
    # $actionString = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/vyashya12/dashboardfeeder/main/test.ps1'))"

    # Trigger to run once
    # $triggerString = New-ScheduledTaskTrigger -AtStartup

    # Registering task
    # Register-ScheduledTask -TaskName $taskNameString -Action $action -Trigger $triggerString -User "SYSTEM" -RunLevel Highest

    # Starting Task
    # Start-ScheduledTask -TaskName $taskNameString

    # Removing task as it has to run once only
    #Unregister-ScheduledTask -TaskName $taskNameString
    
    # Install scheduled task 
    # Create a new scheduled task action to download and run the script
    # [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    # $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/vyashya12/dashboardfeeder/main/installing-agent.ps1'))"

    # Create a new trigger to run the task daily at 12am
    # $trigger = New-ScheduledTaskTrigger -Daily -At 12am

    # Register the scheduled task with the Task Scheduler
    # Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -User "SYSTEM" -RunLevel Highest  
}

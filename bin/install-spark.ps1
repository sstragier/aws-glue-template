Param (
    [Parameter(Mandatory = $true)]
    [string] $InstallDirectory
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$MavenUrl = "https://aws-glue-etl-artifacts.s3.amazonaws.com/glue-common/apache-maven-3.6.0-bin.tar.gz"
$SparkUrl = "https://aws-glue-etl-artifacts.s3.amazonaws.com/glue-1.0/spark-2.4.3-bin-hadoop2.8.tgz"
$WinUtilsVersion = "2.8.3"
$WinUtilsBaseUrl = "https://github.com/steveloughran/winutils/raw/master/hadoop-$WinUtilsVersion/bin"

Function Main() {
    If ($InstallDirectory -contains " ") { Throw "Cannot install to a directory with spaces in the path. This will cause errors for spark" }
    
    If (-not (Get-Command Expand-7Zip -ErrorAction Ignore)) {
        Write-Host "Installing 7Zip Powershell Module..."
        Install-Package -Scope CurrentUser -Force PS7Zip | Out-Null
        Write-Host "Installed 7Zip Powershell Module" -ForegroundColor Green
    }

    InstallMaven
    InstallSpark
    InstallWinUtils
}

Function InstallMaven()
{
    & where.exe /Q mvn
    If ($LastExitCode -eq 0)
    {
        Write-Host "Maven is already installed, skipping installation" -ForegroundColor Yellow
        Return
    }

    $MavenPath = "$InstallDirectory/Maven"
    $MavenZip = "$MavenPath/maven.tar.gz"
    $MavenTar = "$MavenPath/maven.tar"

    [IO.Directory]::CreateDirectory($MavenPath) | Out-Null
    Remove-Item $MavenPath -Include "maven.tar", "maven.tar.gz" -Force | Out-Null

    Write-Host "Downloading Maven..."
    Invoke-WebRequest -Uri $MavenUrl -OutFile $MavenZip
    Write-Host "Downloaed Maven" -ForegroundColor Green

    Write-Host "Installing Maven..."
    Write-Host "Unzipping $MavenZip to $MavenPath"
    Expand-7Zip $MavenZip -DestinationPath $MavenPath -Remove
    Expand-7Zip $MavenTar -DestinationPath $MavenPath -Remove

    $MavenInstallPath = (Get-ChildItem $MavenPath -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1).FullName
    SetEnvironmentVariable "PATH" "$($env:PATH);$MavenInstallPath/bin"
    Write-Host "Installed Maven" -ForegroundColor Green
}

Function InstallSpark()
{
    If ($env:SPARK_HOME -and (Test-Path $env:SPARK_HOME))
    {
        Write-Host "Spark is already installed, skipping installation" -ForegroundColor Yellow
        Return
    }

    $SparkPath = "$InstallDirectory/Spark"
    $SparkZip = "$SparkPath/spark.tgz"
    $SparkTar = "$SparkPath/spark.tar"

    [IO.Directory]::CreateDirectory($SparkPath) | Out-Null
    Remove-Item $SparkPath -Include "spark.tgz", "spark.tar" -Force | Out-Null

    Write-Host "Downloading Spark..."
    Invoke-WebRequest $SparkUrl -OutFile $SparkZip
    Write-Host "Downloaded Spark" -ForegroundColor Green

    Write-Host "Installing Spark..."
    Expand-7Zip $SparkZip -DestinationPath $SparkPath -Remove
    Expand-7Zip $SparkTar -DestinationPath $SparkPath -Remove

    $SparkInstallPath = (Get-ChildItem $SparkPath -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1).FullName
    SetEnvironmentVariable "SPARK_HOME" $SparkInstallPath
    Write-Host "Installed Spark" -ForegroundColor Green
}

Function InstallWinUtils()
{
    If ($env:HADOOP_HOME -and (Test-Path "$env:HADOOP_HOME/bin/winutils.exe") -and (Test-Path "$env:HADOOP_HOME/bin/hadoop.dll"))
    {
        Write-Host "Hadoop is already installed, skipping installation" -ForegroundColor Yellow
    }
    Else
    {
        $HadoopPath = "$InstallDirectory/Hadoop/$WinUtilsVersion"
        $WinUtilsExe = "$HadoopPath/bin/winutils.exe"
        $HadoopDll = "$HadoopPath/bin/hadoop.dll"

        [IO.Directory]::CreateDirectory("$HadoopPath/bin") | Out-Null
        If (Test-Path $WinUtilsExe) { Remove-Item $WinUtilsExe | Out-Null }
        If (Test-Path $HadoopDll) { Remove-Item $HadoopDll | Out-Null }

        Write-Host "Downloading Hadoop's WinUtils..."
        Invoke-WebRequest "$WinUtilsBaseUrl/winutils.exe" -OutFile $WinUtilsExe
        Invoke-WebRequest "$WinUtilsBaseUrl/hadoop.dll" -OutFile $HadoopDll
        Write-Host "Downloaded Hadoop's WinUtils" -ForegroundColor Green
        
        SetEnvironmentVariable "HADOOP_HOME" $HadoopPath
    }
    
    # If winutils.exe is not on PATH, add it
    & where.exe /Q winutils
    If ($LastExitCode -ne 0)
    {
        SetEnvironmentVariable "PATH" "$($env:PATH);%HADOOP_HOME%/bin"
        Write-Host "Added winutils to PATH" -ForegroundColor Green
    }
}

Function SetEnvironmentVariable($Name, $Value)
{
    $Original = [Environment]::GetEnvironmentVariable($Name)
    [Environment]::SetEnvironmentVariable($Name, $Value, [EnvironmentVariableTarget]::Process)
    [Environment]::SetEnvironmentVariable($Name, $Value, [EnvironmentVariableTarget]::Machine)

    Write-Host "Changed Environment Variable: $Name"
    Write-Host "From: $Original"
    Write-Host "-----------------------------------"
    Write-Host "To: $Value"
    Write-Host "-----------------------------------"
    Write-Host ""
}

Main
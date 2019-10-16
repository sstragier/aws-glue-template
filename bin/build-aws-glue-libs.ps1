$ErrorActionPreference = "Stop"

$AwsGlueLibsPath = Resolve-Path "$PSScriptRoot/.."
$AwsGlueJarsPath = "$AwsGlueLibsPath/jars"
$SparkConfigPath = "$AwsGlueLibsPath/conf"
$InstallScript = "install-spark.ps1"

Function Main()
{
    VerifySparkIsInstalled
    InstallDependencies
    CreateSparkConfig
}

Function VerifySparkIsInstalled()
{
    # Check for Maven
    & where.exe /Q mvn
    If ($LastExitCode -ne 0) { Throw "Maven is not installed, run: $InstallScript" }

    # Check for Spark
    If (!$env:SPARK_HOME) { Throw "Spark is not installed, run: $InstallScript" }
}

Function InstallDependencies()
{
    [IO.Directory]::CreateDirectory($AwsGlueJarsPath) | Out-Null

    Write-Host "Cleaning dependency folder..."
    Remove-Item "$AwsGlueJarsPath/*" -Force
    Write-Host "Cleaned dependency folder" -ForegroundColor Green

    Write-Host "Installing dependencies..."
    & mvn -f "$AwsGlueLibsPath/pom.xml" "-DoutputDirectory=$AwsGlueJarsPath" "dependency:copy-dependencies"
    Write-Host "Installed dependencies" -ForegroundColor Green

    Write-Host "Removing duplicate dependencies that conflict with Spark..."
    RemoveDependenciesDuplicatedFromSpark
    Write-Host "Removed duplicate dependencies that conflict with Spark" -ForegroundColor Green
}

Function RemoveDependenciesDuplicatedFromSpark()
{
    $SparkJars = GetDependencies "$env:SPARK_HOME/jars"
    $AwsGlueJars = GetDependencies $AwsGlueJarsPath

    ForEach ($JarName In $AwsGlueJars.Keys | Sort-Object)
    {
        If ($SparkJars.ContainsKey($JarName))
        {
            Remove-Item $AwsGlueJars[$JarName] -Force
            Write-Host "Deleted: $($AwsGlueJars[$JarName])"
        }
    }
}

Function GetDependencies
{
    [OutputType([HashTable])]
    Param ([string] $Folder)

    $Map = @{}

    Get-ChildItem $Folder -Filter "*.jar" |
        ForEach-Object `
        {
            $_.Name -match "^(?<name>.*?)[\.\-_](?<version>\d+\.\d+(\.(\d+))?).*\.jar$" | Out-Null
            $Map[$Matches["name"]] = $_.FullName
        }

    Return $Map
}

Function CreateSparkConfig()
{
    Write-Host "Creating Spark config files..."
    $SparkConfigFile = "$SparkConfigPath/spark-defaults.conf"

    [IO.Directory]::CreateDirectory($SparkConfigPath) | Out-Null
    Remove-Item "$SparkConfigPath/*" -Filter "*.conf" -Force | Out-Null

    # The config file tells Spark to include the AWS Glue jars
    # See the launch.json for how the config file is passed to Spark
    $Path = $AwsGlueJarsPath -replace "\\", "/"
    $Contents = (
        "spark.driver.extraClassPath=$Path/*",
        "spark.executor.extraClassPath=$Path/*"
    ) -join "`r"
    [IO.File]::WriteAllText($SparkConfigFile, $Contents)
    Write-Host "Created Spark config files" -ForegroundColor Green
}

Main
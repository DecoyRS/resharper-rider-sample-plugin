Param(
    [Parameter(Mandatory=$true)]
    [string]$ReSharperApiKey,
    [Parameter(Mandatory=$true)]
    [string]$RiderUsername,
    [Parameter(Mandatory=$true)]
    [string]$RiderPassword,
    [string]$Configuration = "Release"
)

$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$OutputDirectory = "$PSScriptRoot\output"

Remove-Item $OutputDirectory -Force -Recurse
& dotnet pack SamplePlugin.sln --configuration $Configuration --output $OutputDirectory # --NoPackageAnalysis

$ReSharperPackageFile = Get-ChildItem "$OutputDirectory\SamplePlugin.ReSharper.*.nupkg"

$RiderOutputDirectory = "$OutputDirectory\rider-SamplePlugin"
mkdir "$RiderOutputDirectory"
mkdir "$RiderOutputDirectory\dotnet" > $null
Copy-Item -Path "$PSScriptRoot\src\SamplePlugin.ReSharper\bin\SamplePlugin.Rider\$Configuration\SamplePlugin.Rider.*" -Destination "$RiderOutputDirectory\dotnet"
mkdir "$RiderOutputDirectory\META-INF" > $null
Copy-Item -Path "$PSScriptRoot\src\plugin.xml" -Destination "$RiderOutputDirectory\META-INF"
& "$PSScriptRoot\..\tools\7zip.exe" 

Write-Host dotnet nuget push $ReSharperPackageFile --source "https://resharper-plugins.jetbrains.com/api/v2/package" --api-key $ApiKey
Write-Host java -jar "$PSScriptRoot\..\tools\plugin-repository-rest-client.jar" upload -file "$OutputDirectory\rider-SamplePlugin.zip" -plugin rider-SamplePlugin -username $RiderUsername -password $RiderPassword
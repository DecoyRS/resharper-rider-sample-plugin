Param(
    #[Parameter(Mandatory=$true)]
    [string]$ReSharperApiKey,
    #[Parameter(Mandatory=$true)]
    [string]$RiderUsername,
    #[Parameter(Mandatory=$true)]
    [string]$RiderPassword,
    [string]$Configuration = "Release",
    [string]$Version = "1.2.3"
)

$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$OutputDirectory = "$PSScriptRoot\output"

# ReSharper
Remove-Item $OutputDirectory -Force -Recurse
& dotnet pack SamplePlugin.sln /p:PackageVersion=$Version --configuration $Configuration --output $OutputDirectory
$ReSharperPackageFile = Get-ChildItem "$OutputDirectory\ReSharper.SamplePlugin.*.nupkg"

# Rider
$RiderOutputDirectory = "$OutputDirectory\rider-SamplePlugin"
$RiderPluginXml = [xml] (Get-Content "$PSScriptRoot\src\plugin.xml")
$RiderPluginId = $RiderPluginXml."idea-plugin".id

# Rider :: dotnet
mkdir "$RiderOutputDirectory" > $null
mkdir "$RiderOutputDirectory\dotnet" > $null
Copy-Item -Path "$PSScriptRoot\src\ReSharper.SamplePlugin\bin\ReSharper.SamplePlugin.Rider\$Configuration\ReSharper.SamplePlugin.Rider.*" -Destination "$RiderOutputDirectory\dotnet"

# Rider :: idea
$WaveSpec = ([xml] (Get-Content "$PSScriptRoot\src\Versions.props")).Project.PropertyGroup.SdkVersion
$WaveSpec = "$($WaveSpec.Substring(2,2))$($WaveSpec.Substring(5,1))"
$RiderPluginXml."idea-plugin".version = $Version
$RiderPluginXml."idea-plugin"."idea-version".setAttribute("since-build", "$WaveSpec.0")
$RiderPluginXml."idea-plugin"."idea-version".setAttribute("until-build", "$WaveSpec.*")
mkdir "$RiderOutputDirectory\META-INF" > $null
$RiderPluginXml.Save("$RiderOutputDirectory\META-INF\plugin.xml")

# Rider :: zip
$RiderPackageFile = "$OutputDirectory\$RiderPluginid.zip"
& "$PSScriptRoot\..\tools\7za.exe" a "$RiderPackageFile" "$RiderOutputDirectory" > $null

# Publish
Write-Host dotnet nuget push $ReSharperPackageFile --source "https://resharper-plugins.jetbrains.com/api/v2/package" --api-key $ReSharperApiKey
Write-Host java -jar "$PSScriptRoot\..\tools\plugin-repository-rest-client.jar" upload -file "$RiderPackageFile" -plugin "$RiderPluginId" -username $RiderUsername -password $RiderPassword

# git tag $Version
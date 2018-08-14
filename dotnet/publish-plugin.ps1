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

Remove-Item $OutputDirectory -Force -Recurse
& dotnet pack SamplePlugin.sln /p:PackageVersion=$Version --configuration $Configuration --output $OutputDirectory # --NoPackageAnalysis

$ReSharperPackageFile = Get-ChildItem "$OutputDirectory\SamplePlugin.ReSharper.*.nupkg"

$RiderOutputDirectory = "$OutputDirectory\rider-SamplePlugin"
$PluginXmlFile = "$RiderOutputDirectory\META-INF\plugin.xml"
mkdir "$RiderOutputDirectory"
mkdir "$RiderOutputDirectory\dotnet" > $null
Copy-Item -Path "$PSScriptRoot\src\SamplePlugin.ReSharper\bin\SamplePlugin.Rider\$Configuration\SamplePlugin.Rider.*" -Destination "$RiderOutputDirectory\dotnet"
mkdir "$RiderOutputDirectory\META-INF" > $null
Copy-Item -Path "$PSScriptRoot\src\plugin.xml" -Destination "$PluginXmlFile"


$pluginXml = [xml] (Get-Content "$PluginXmlFile")
$waveSpec = ([xml] (Get-Content "$PSScriptRoot\src\Versions.props")).Project.PropertyGroup.SdkVersion
$waveSpec = "$($waveSpec.Substring(2,2))$($waveSpec.Substring(5,1))"
$pluginXml."idea-plugin".version = $Version
$pluginXml."idea-plugin"."idea-version".setAttribute("since-build", "$waveSpec.0")
$pluginXml."idea-plugin"."idea-version".setAttribute("until-build", "$waveSpec.*")
$pluginXml.Save("$PluginXmlFile")

exit
& "$PSScriptRoot\..\tools\7za.exe" a "$OutputDirectory\rider-SamplePlugin.zip" "$RiderOutputDirectory"

Write-Host dotnet nuget push $ReSharperPackageFile --source "https://resharper-plugins.jetbrains.com/api/v2/package" --api-key $ApiKey
Write-Host java -jar "$PSScriptRoot\..\tools\plugin-repository-rest-client.jar" upload -file "$OutputDirectory\rider-SamplePlugin.zip" -plugin rider-SamplePlugin -username $RiderUsername -password $RiderPassword
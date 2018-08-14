Param(
    [Parameter(Mandatory=$true)]
    $RootSuffix,
    $Version = "1.0.0"
)

$UseEAP = $false
$PluginId = "SamplePlugin.ReSharper"

$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

function ExecSafe([scriptblock] $cmd) {
    & $cmd
    if ($LastExitCode -ne 0) { throw "The following call failed with exit code $LastExitCode. '$cmd'" }
}

# Determine download link
if ($UseEAP) {
	$ReleaseUrl = "https://data.services.jetbrains.com/products/releases?code=RSU&type=eap"
} else {
	$ReleaseUrl = "https://data.services.jetbrains.com/products/releases?code=RSU&type=release"
}
$DownloadLink = [uri] $(Invoke-WebRequest -UseBasicParsing $ReleaseUrl | ConvertFrom-Json).RSU[0].downloads.windows.link

# Download installer
$InstallerFile = "$PSScriptRoot\installer\$($DownloadLink.segments[-1])"
if (!(Test-Path $InstallerFile)) {
	mkdir -Force $(Split-Path $InstallerFile -Parent) > $null
	Write-Output "Downloading from $DownloadLink"
	(New-Object System.Net.WebClient).DownloadFile($DownloadLink, $InstallerFile)
} else {
	Write-Output "Using $($DownloadLink.segments[-1]) from cache"
}

# Execute installer
Write-Output "Installing experimental hive"
ExecSafe { & $InstallerFile "/VsVersion=15.0" "/SpecificProductNames=ReSharper" "/Hive=$RootSuffix" "/Silent=True" | Out-Null }

$PluginRepository = "$env:LOCALAPPDATA\JetBrains\plugins"
$InstallationDirectory = $(Get-ChildItem "$env:APPDATA\JetBrains\ReSharperPlatformVs*\v*_*$RootSuffix\NuGet.Config").Directory

# Adapt packages.config
if (Test-Path "$InstallationDirectory\packages.config") {
    $PackagesXml = [xml] (Get-Content "$InstallationDirectory\packages.config")
} else {
    $PackagesXml = [xml] ("<?xml version=`"1.0`" encoding=`"utf-8`"?><packages></packages>")
}

if ($null -eq $PackagesXml.SelectSingleNode(".//package[@id='$PluginId']/@id")) {
    $PluginNode = $PackagesXml.CreateElement('package')
    $PluginNode.setAttribute("id", "$PluginId")
    $PluginNode.setAttribute("version", "$Version")

    $PackagesNode = $PackagesXml.SelectSingleNode("//packages")
    $PackagesNode.AppendChild($PluginNode)

    $PackagesXml.Save("$InstallationDirectory\packages.config")
}

# Install plugin
$OutputDirectory = "$PSScriptRoot\output"
$NuGetFile = "$PSScriptRoot\..\tools\nuget.exe"

ExecSafe { & dotnet pack SamplePlugin.sln /p:PackageVersion=$Version --output "$OutputDirectory" }
ExecSafe { & "$NuGetFile" install SamplePlugin.ReSharper -OutputDirectory "$PluginRepository" -Source "$OutputDirectory" -DependencyVersion Ignore }

Write-Output "Re-installing experimental hive"
ExecSafe { & "$InstallerFile" "/VsVersion=15.0" "/SpecificProductNames=ReSharper" "/Hive=$RootSuffix" "/Silent=True" | Out-Null }

# Adapt user project file
$HostIdentifier = "$($InstallationDirectory.Parent.Name)_$($InstallationDirectory.Name.Split('_')[-1])"
$UserProjectXmlFile = "$PSScriptRoot\src\$PluginId\$PluginId.csproj.user"

if (!(Test-Path "$UserProjectXmlFile")) {
    Set-Content -Path "$UserProjectXmlFile" -Value "<Project><PropertyGroup><HostFullIdentifier></HostFullIdentifier></PropertyGroup></Project>"
}

$ProjectXml = [xml] (Get-Content "$UserProjectXmlFile")
$HostIdentifierNode = $ProjectXml.SelectSingleNode(".//HostFullIdentifier")
$HostIdentifierNode.InnerText = $HostIdentifier
$ProjectXml.Save("$UserProjectXmlFile")

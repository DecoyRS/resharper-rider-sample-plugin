$RootSuffix = "Resharper0"
$UseEAP = $true
$PluginId = "SamplePlugin.ReSharper"

$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

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
& $InstallerFile "/VsVersion=15.0" "/SpecificProductNames=ReSharper" "/Hive=$RootSuffix" "/Silent=True" | Out-Null

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

# Adapt user project file
$HostIdentifier = "$($InstallationDirectory.Parent.Name)_$($InstallationDirectory.Name.Split('_')[-1])"
$UserProjectXmlFile = "$PSScriptRoot\src\SamplePlugin.ReSharper\SamplePlugin.ReSharper.csproj.user"

if (!(Test-Path "$UserProjectXmlFile")) {
    Set-Content -Path "$UserProjectXmlFile" -Value "<Project><PropertyGroup><HostFullIdentifier></HostFullIdentifier></PropertyGroup></Project>"
}

$ProjectXml = [xml] (Get-Content "$UserProjectXmlFile")
$HostIdentifierNode = $ProjectXml.SelectSingleNode(".//HostFullIdentifier")
$HostIdentifierNode.InnerText = $HostIdentifier
$ProjectXml.Save("$UserProjectXmlFile")

# Install plugin
$OutputDirectory = "$PSScriptRoot\output"
$NuGetFile = "$PSScriptRoot\..\tools\nuget.exe"

& dotnet pack SamplePlugin.sln --output "$OutputDirectory"
& "$NuGetFile" install SamplePlugin.ReSharper -OutputDirectory "$PluginRepository" -Source "$OutputDirectory" -DependencyVersion Ignore
& "$InstallerFile" "/VsVersion=15.0" "/SpecificProductNames=ReSharper" "/Hive=$RootSuffix" "/Silent=True" | Out-Null
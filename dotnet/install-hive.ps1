$RootSuffix = "Resharper0"
$UseEAP = $true

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
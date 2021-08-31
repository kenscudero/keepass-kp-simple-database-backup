# Do not remove this test for UTF-8: if “Ω” doesn’t appear as greek uppercase omega letter enclosed in quotation marks, you should use an editor that supports UTF-8, not this one.
$ErrorActionPreference = 'Stop';

$packageName		= $env:ChocolateyPackageName
$toolsDir		= "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url			= 'https://github.com/marvinweber/KPSimpleBackup/releases/download/v1.4.0/KPSimpleBackup-v1.4.0.zip'
$checksum		= '7091CEFBAF1E06D5231AF748187B060498FF2B6BC9BA39D806AD31E611D52FB4'
$checksumType		= 'SHA256'
$KeePassZipFileName	= 'KPSimpleBackup.zip'
$sourcePluginsDir	= "$(Join-Path -Path $toolsDir -ChildPath Plugins)"
$sourceZipFileFullPath	= "$(Join-Path -Path $sourcePluginsDir -ChildPath $KeePassZipFileName)"

Get-ChocolateyWebFile -PackageName "$packageName" `
                      -Url $url -FileFullPath "$sourceZipFileFullPath" `
                      -Checksum "$checksum" -ChecksumType "$checksumType"

Get-ChocolateyUnzip -FileFullPath $sourceZipFileFullPath -Destination $sourcePluginsDir

$packageSearch		= 'KeePass Password Safe*'
$KeePassPath		= ''

if ([array]$key = Get-UninstallRegistryKey -SoftwareName $packageSearch) {
  $KeePassPath = $key.InstallLocation
}

if ([string]::IsNullOrEmpty($KeePassPath)) {
  Write-Verbose "Cannot find '$packageSearch' in Add / Remove Programs or Programs and Features."
  Write-Verbose "Searching '$env:ChocolateyToolsLocation' for portable install..."
  $portPath = Join-Path -Path $env:ChocolateyToolsLocation -ChildPath "keepass"
  $KeePassPath = Get-ChildItem -Directory "$portPath*" -ErrorAction SilentlyContinue

  if ([string]::IsNullOrEmpty($KeePassPath)) {
    Write-Verbose "Searching '$env:Path' for unregistered install..."
    $installFullName = Get-Command -Name keepass -ErrorAction SilentlyContinue
    if ($installFullName) {
      $KeePassPath = Split-Path $installFullName.Path -Parent
    }
  }
}

if ([string]::IsNullOrEmpty($KeePassPath)) {
  Write-Error -Message 'Cannot find Keepass! Exiting now as it''s needed to install the plugin.' -ErrorAction Stop
}

Write-Host "Found Keepass install location at '$KeePassPath'."

$KeePassPluginPath	= 'Plugins'
$KeePassPluginName	= 'KPSimpleBackup.plgx'
$sourceFileFullPath	= "$(Join-Path -Path $sourcePluginsDir -ChildPath plgx\$KeePassPluginName)"
$destPluginPath		= "$(Join-Path -Path $KeePassPath -ChildPath $KeePassPluginPath)"
$destFileFullPath	= "$(Join-Path -Path $destPluginPath -ChildPath $KeePassPluginName)"

$errorMessage		=
if (Test-Path $sourceFileFullPath) {
  if (Test-Path $destPluginPath) {
    Write-Host "Copying '$sourceFileFullPath'`n  to '$destFileFullPath'"
    Copy-Item -Path $sourceFileFullPath -Destination $destFileFullPath
  } else {
      $errorMessage = 'Cannot find Keepass plugin destination!'
  }
} else {
    $errorMessage = 'Cannot find Keepass plugin source!'
}
if ($errorMessage) {
  Write-Error -Message "$errorMessage Exiting now as it's needed to install the plugin." -ErrorAction Stop
}

$processName		= 'KeePass'

if (Get-Process -Name $processName -ErrorAction SilentlyContinue) {
  Write-Warning "$processName is currently running.`n$($packageName) will be available at next restart."
} else {
  Write-Host "$($packageName) will be loaded the next time $processName is started."
}

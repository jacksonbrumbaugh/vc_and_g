<# RULER ----15--------25-----------------------50----------------------------80                 100                 120
Modified: 2024-03-03
By: Jackson B
#>
$ModuleRootDir = $PSScriptRoot
$ModuleName = Split-Path $ModuleRootDir -Leaf

$ChildFolderArray = Get-ChildItem $ModuleRootDir -Directory

$NoExportKeywordArray = @(
  "Help",
  "Support"
)

foreach ( $ThisFolder in $ChildFolderArray ) {
  $ChildFunctionFileArray = Get-ChildItem -Path (Get-Item $ModuleRootDir\$ThisFolder) -Include "*.ps1" -Recurse

  foreach ( $ThisFunctionFile in $ChildFunctionFileArray ) {
    $ThisFunctionFileItem = Get-Item $ThisFunctionFile
    $ThisFunctionFileFullName = $ThisFunctionFileItem.FullName

    # Dot-Sourcing; loads the function as part of the module
    . $ThisFunctionFileFullName

    $ThisFolderName = Split-Path (Split-Path $ThisFunctionFileFullName) -Leaf
    $ThisFunctionName = (Split-Path $ThisFunctionFileFullName -Leaf).replace( '.ps1', '' )

    $doExport = $true
    foreach ( $ThisKeyword in $NoExportKeywordArray ) {
      if ( $ThisFolderName -match $ThisKeyword ) {
        $doExport = $false

        break

      } # End block:if a Do No Export Keyword is found

    } # End block:foreach Do Not Export Keyword

    # Lets users use / see the function outside of this module
    if ( $doExport ) { Export-ModuleMember $ThisFunctionName }

  } # End block:foreach Function

} # End block:foreach Dir in ChildFolderArray

$AliasArray = (Get-Alias).Where{ $_.Source -eq $ModuleName }
$AliasNameArray = $AliasArray.Name -replace "(.*) ->.*","`$1"
foreach ( $ThisAlias in $AliasNameArray ) {
  # Lets users use / see the alias
  Export-ModuleMember -Alias $ThisAlias
}

Get-ChildItem $PSScriptRoot\*.ps1 -Exclude $ExcludeList | ForEach-Object {
  . $_.FullName
}

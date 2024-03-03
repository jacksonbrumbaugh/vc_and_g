<# RULER ----15--------25-----------------------50----------------------------80                 100                 120
Modified: 2024-03-03
By: Jackson B
#>
function Select-TcgExportFile {
  [CmdletBinding()]

  param (
    [string]
    $Title = "Select the TCG Player Inventory Export File",

    [string]
    $InitialDirectory = (Join-Path $env:HOMEDRIVE (Join-Path $env:HOMEPATH "Downloads"))
  ) # End block:param

  process {
    $ParamHash_SelectFile = @{}

    foreach ( $ThisInputParameter in ("Title", "InitialDirectory") ) {
      $ParameterValue = Get-Variable $ThisInputParameter -ValueOnly

      if ( -not [string]::IsNullOrEmpty( $ParameterValue ) ) {
        $ParamHash_SelectFile.$ThisInputParameter = $ParameterValue
      }

    } # End foreach:block Input Parameter

    $SelectedFileName = Select-File @ParamHash_SelectFile

    $TcgExportFullName = if ( [string]::IsNullOrEmpty($SelectedFileName) ) {
      $null
    } else {
      $SelectedFileName
    }

    Write-Output $TcgExportFullName

  } # End block:process

} # End function

<# RULER ----15--------25-----------------------50----------------------------80                 100                 120
Modified: 2024-04-29
By: Jackson B
#>
function Select-OrderInvoiceFile {
  [CmdletBinding()]

  param (
    [string]
    $Title = "Select the Order Invoice TXT File",

    [string]
    $InitialDirectory = (Join-Path $env:HOMEDRIVE (Join-Path $env:HOMEPATH "Downloads"))
  ) # End block:param

  process {
    #region Build parameters for the Select File function
    $ParamHash_SelectFile = @{
      Multi = $tru
    }

    foreach ( $ThisInputParameter in ("Title", "InitialDirectory") ) {
      $ParameterValue = Get-Variable $ThisInputParameter -ValueOnly

      if ( -not [string]::IsNullOrEmpty( $ParameterValue ) ) {
        $ParamHash_SelectFile.$ThisInputParameter = $ParameterValue
      }

    } # End foreach:block Input Parameter

    #endregion

    $SelectedFileName = Select-File @ParamHash_SelectFile

    $OrderInvoiceFullName = if ( [string]::IsNullOrEmpty($SelectedFileName) ) {
      $null
    } else {
      $SelectedFileName
    }

    Write-Output $OrderInvoiceFullName

  } # End block:process

} # End function

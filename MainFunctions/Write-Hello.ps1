<#
Modified: 2024-03-03
By: Jackson B
#>
function Write-Hello {
  [CmdletBinding()]

  param (
    [string[]]
    $Name
  ) # End block:param

  process {
    $NameArray = if ( $Name.Count -eq 0 ) {
      "John"
    } else {
      $Name
    }

    foreach ( $ThisName in $NameArray ) {
      $GreetingLine = "Hello, {0}" -f $ThisName

      Write-Host $GreetingLine -ForegroundColor Green

    } # End block:foreach Name

  } # End block:process

} # End function

foreach ( $ThisAlias in ("Hello") ) {
  Set-Alias -Name $ThisAlias -Value Write-Hello
} # End block:foreach Alias

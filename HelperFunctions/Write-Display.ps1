<# RULER ----15--------25-----------------------50----------------------------80                 100                 120
Modified: 2024-03-05
By: Jackson B
#>
function Write-Display {
  [CmdletBinding()]

  param (
    [Parameter(
      Position = 0
    )]
    [string[]]
    $Message,

    [switch]
    $Pulse,

    [double]
    $PulseSeconds = 0.5,

    [ConsoleColor]
    $ForegroundColor,

    [ConsoleColor]
    $BackgroundColor
  ) # End block:param

  process {
    foreach ( $ThisStep in $Message ) {
      $ParamHash_Display = @{
        Object = $ThisStep
      }

      if ( $ForegroundColor ) { $ParamHash_Display.ForegroundColor = $ForegroundColor }
      if ( $BackgroundColor ) { $ParamHash_Display.BackgroundColor = $BackgroundColor }

      Write-Host @ParamHash_Display

      if ( $Pulse ) { Start-Sleep -Milliseconds (1000 * $PulseInSeconds) }

    } # End block:foreach Line in Message

    Write-Host ""

  } # End block:process

} # End function:Write-Step

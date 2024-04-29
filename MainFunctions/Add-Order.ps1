<# RULER ----15--------25-----------------------50----------------------------80                 100                 120
Modified: 2024-04-29
By: Jackson B
#>
function Add-Order {
  [CmdletBinding()]

  param (
    [Parameter(
      Position = 0
    )]
    [SupportsWildcards()]
    [ValidateScript(
      { Test-Path $_ }
    )]
    [string[]]
    $Path,

    [OrderSource]
    $Source
  ) # End block:param

  process {
    $OrderInvoicePathArray = if ( $Path.Count -gt 0 ) {
      $Path

    } else {
      Select-OrderInvoiceFile

    } # End block:if-else getting Invoice file if none were input

    $RawOrderDataArray = New-Object -TypeName System.Collections.ArrayList

    $CurrentOrderNumber = $null
    $OrderIndex = 0

    foreach ( $ThisPath in $OrderInvoicePathArray ) {
      $RawContent = Get-Content $Path

      $isGatheringOrderData = $false
      foreach ( $ThisLine in $RawContent ) {
        if ( -not $isGatheringOrderData -and ($ThisLine -match "^Order Number") ) {
          $isGatheringOrderData = $true

          <#
          e.g.
          Order Number: F137405E-60B448-E7107
          #>
          $CurrentOrderNumber = $ThisLine -replace "Order Number: (.*)", '$1'

          $OrderIndex++

          $RawOrderDataArray.Add(
            [PSCustomObject]@{
              Index     = $OrderIndex
              Number    = $CurrentOrderNumber
              LineArray = New-Object -TypeName System.Collections.ArrayList
            }
          ) | Out-Null

        } # End block:if Start Gathering Order Data

        if ( $isGatheringOrderData ) {
          $RawOrderDataArray[$OrderIndex].LineArray.Add( $ThisLine ) | Out-Null

        } # End block:if Gathering Order Data

        <#
        check for # of # to know its the end of an order

        e.g.
        Order Number: F137405E-4EBD3B-BF3BF 8 of 8
        #>
        if ( $ThisLine -match "^Order Number.*\d{} of \d{}" ) {
          $CurrentPageOfOrder = $ThisLine -replace ".* (\d*) of .*", '$1'
          $TotalPagesOfOrder = $ThisLine -replace ".* of (\d*)", '$1'

          if ( $CurrentPageOfOrder -eq $TotalPagesOfOrder ) {
            $isGatheringOrderData = $false

          } # End block:if Stop Gathering Order Data

        } # End block:if hit the end of an order

      } # End block:foreach Line of the Order Invoice file content

      <#
      With raw order data 
      #>

    } # End block:foreach Path

  } # End block:process

} # End function

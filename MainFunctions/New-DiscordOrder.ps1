<# RULER ----15--------25-----------------------50----------------------------80                 100                 120
Modified: 2024-03-05
By: Jackson B
#>
function New-DiscordOrder {
  [CmdletBinding()]

  param () # End block:param

  begin {
    $CustomTcgpHeader = @(
      "TCG_Id",
      "ProductLine",
      "Set",
      "Name",
      "Title",
      "Number",
      "Rarity",
      "Condition",
      "Market",
      "DirectLow",
      "LowPlusShipping",
      "Low",
      "Qty",
      "AddToQty",
      "OurPrice",
      "Photo URL"
    )

  } # End block:begin

  process {
    $ParamHash_Error = @{
      Message     = $null
      ErrorAction = "Stop"
    }

    $StartTime = Get-Date

    <#
    did this totally unnecessary clunky replace to show that we made the small pivot of E -> D
    #>
    $VcgTcgOrderStartingCode = "F137405E".replace( "E", "D")

    $OrderNumberGUID = $VcgTcgOrderStartingCode + "-"
    $OrderNumberGUID += ((New-GUID) -split "-")[0 .. 1].ToUpper() -join "-"

    $ProcessMsgArray = @(
      "Soon Windows file explorer will open",
      "1st: please select the TCG Player inventory export *.csv file",
      "2nd: please select the file containing the list of card(s) desired for the Discord order",
      "3rd: wait for the process to finish",
      "",
      "Order Invoice Number: $($OrderNumberGUID)"
    )

    Write-Display -Message $ProcessMsgArray -ForegroundColor "Green" -Pulse

    $TcgpInventoryFullName = Select-TcgExportFile
    $DiscordOrderFullName = Select-DiscordOrderListFile

    $File = @{
      TCGP = @{
        FullName = $TcgpInventoryFullName
      }
      DiscordOrder = @{
        FullName = $DiscordOrderFullName
      }
    }

    foreach ( $ThisFile in $File.Keys ) {
      if ( [string]::IsNullOrEmpty($File.$ThisFile.FullName) ) {
        $ParamHash_Error.Message = "Failed to select the $($ThisFile) file - ending discord order checker. "

        Write-Error @ParamHash_Error

      } # End block:if the selected file is blank

      $File.$ThisFile.Item = Get-Item $File.$ThisFile.FullName
      $File.$ThisFile.Name = $File.$ThisFile.Item.Name

    } # End block:foreach File TCG Player Inventory Export & Discord Order List

    $InventoryArray = Import-CSV $File.TCGP.FullName -Header $CustomTcgpHeader

    $WantListContent = Get-Content $File.DiscordOrder.FullName

    Write-Display @(
      ("Discord Order Want List File: {0}" -f $File.DiscordOrder.Name),
      "",
      "Top several lines from the want list file"
    )

    foreach ( $ThisLine in $WantListContent[0 .. 5] ) {
      Write-Host $ThisLine
    }

    Write-Display @(
      "",
      ("Exported Inventory File: {0}" -f $File.TCGP.Name),
      ("Unique Card Inventory Count: {0:N0}" -f ($InventoryArray.Count - 1))
    )

    $useSimpleCrossRefMode = $true
    $WantCardArray = foreach ( $ThisWantRow in $WantListContent ) {
      $CardName, $SetNumber = if ( $ThisWantRow -match "\(" ) {
        $useSimpleCrossRefMode = $false

        $Name = $ThisWantRow -replace "^\d{1,3} (.*) \(.*",'$1'
        $SetNum = $ThisWantRow -replace ".*\) (.*)",'$1'

        <#
        Special printings (e.g. Foil, Extended Art)
        are marked from Moxfield with *F*, *E* (possibly other codes)
        #>
        if ( $SetNum -match "\*" ) {
          $SetNum, $AltPrintingCode = $SetNum -split " "
          $Name += " " + $AltPrintingCode
        }

        $Name, $SetNum

      } else {
        ($ThisWantRow -replace "\d{1,3} (.*)",'$1'), $null
      }

      [PSCustomObject]@{
        Name   = $CardName
        Number = $SetNumber
        Raw    = $ThisWantRow
      }

    } # End block:foreach This Want Row

    $CrossRefMsg = "Cross referencing b/t order want list & our inventory"

    if ( -not $useSimpleCrossRefMode ) {
      $CrossRefMsg += " using Set Number and a focus on Foil"
    }

    Write-Display @(
      $CrossRefMsg
    )

    $WeHaveArray = @()
    foreach ( $ThisWantCard in $WantCardArray ) {
      $NameMatchArray = $InventoryArray.where{ $_.Name -match $ThisWantCard.Name }

      $OurStock = if ( $useSimpleCrossRefMode ) {
        $NameMatchArray
      } else {
        $NameMatchArray.where{ $_.Number -eq $ThisWantCard.Number }
      }

      foreach ( $OurStockRow in $OurStock ) {
        if ( $OurStockRow.Qty -eq 0 ) {
          continue
        }

        if ( -not $useSimpleCrossRefMode ) {
          <#
          John has noticed that buyers on this Discord server get super picky
          about specific set & printing (like foil vs non-foil)
          #>
          $WantFoil = $ThisWantCard.Raw -match "\*F\*"
          $isOurStockFoil = $OurStockRow.Condition -match "Foil"

          if ( $WantFoil -and (-not $isOurStockFoil) ) {
            continue
          }

          if ( (-not $WantFoil) -and $isOurStockFoil ) {
            continue
          }

        } # End block:if caring about Foil printing

        $WeHaveArray += [PSCustomObject]@{
          Name        = $ThisWantCard.Name
          Set         = $OurStockRow.Set
          Condition   = $OurStockRow.Condition
          Quantity    = $OurStockRow.Qty
          Price       = '${0:N2}' -f ($OurStockRow.OurPrice -as [double])
          SetNumber   = $OurStockRow.Number
          Rarity      = $OurStockRow.Rarity
        }

      } # End block:foreach row from Our Stock

    } # End block:foreach Wanted Card from the Discord Order

    $DownloadsFolder = Join-Path $env:HOMEDRIVE (Join-Path $env:HOMEPATH "Downloads")

    $InventoryCheckReportName = "InventoryCheck-$($OrderNumberGUID).csv"
    $FullDiscordCheckReport = Join-Path $DownloadsFolder $InventoryCheckReportName

    if ( $WeHaveArray.Count -eq 0 ) {
      New-Item -ItemType File -Path $FullDiscordCheckReport | Out-Null
    } else {
      $WeHaveArray | Export-CSV -NTI -Path $FullDiscordCheckReport
    }

    $ReportHeader = "INVENTORY CHECK REPORT"
    Write-Display @(
      $ReportHeader,
      ( "-" * $ReportHeader.length )
      "",
      "Date: $($StartTime.ToString( 'ddd yyyy-MM-dd' ))",
      "Time: $($StartTime.ToString( 'HH:mm' ))",
      "",
      "Order Number: $($OrderNumberGUID)"
    )

    $WeHaveArray | Select-Object -Property Name, SetNumber, Condition, Quantity, Set | Format-Table

    <#
    Enhancement Idea

    export an updated Inventory CSV file that can be re-uploaded to TCG Player
    with the quantities correctly minus-d the pulled Discord Order cards

    .. to do that .. would need a step to confirm which exact sets (if multiple)
    were pulled for the Discorrd order
    #>

  } # End block:process

} # End function

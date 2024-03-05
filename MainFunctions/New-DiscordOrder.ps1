<# RULER ----15--------25-----------------------50----------------------------80                 100                 120
Modified: 2024-03-04
By: Jackson B
#>
function New-DiscordOrder {
  [CmdletBinding()]

  param () # End block:param

  process {
    $ParamHash_Error = @{
      Message     = $null
      ErrorAction = "Stop"
    }

    $ProcessMsgArray = @(
      "Soon Windows file explorers will open",
      "1st: please select the TCG Player inventory export *.csv file",
      "2nd: please select the file containing the list of card(s) desired for the Discord order",
      "3rd: wait for the process to finish",
      ""
    )

    foreach ( $ThisLine in $ProcessMsgArray ) {
      Write-Host $ThisLine -ForegroundColor Green

      Start-Sleep 1

    } # End block:foreach Line detailing the process about to happen

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

    $InventoryArray = Import-CSV $File.TCGP.FullName -Header $CustomTcgpHeader

    $InProgressMsgArray = @(
      ("Exported Inventory File: {0}" -f $File.TCGP.Name),
      ("Unique Inventory Count: {0:N0}" -f ($InventoryArray.Count - 1)),
      "",
      ("Discord Order File: {0}" -f $File.DiscordOrder.Name)
    )

    foreach ( $ThisLine in $InProgressMsgArray ) {
      Write-Host $ThisLine
    }

    $WantListContent = Get-Content $File.DiscordOrder.FullName
    foreach ( $ThisLine in $WantListContent ) {
      Write-Host $ThisLine
    }

    for ( $n = 0; $n -lt 2; $n++ ) { Write-Host "" }

    $WantCardArray = foreach ( $ThisWantRow in $WantListContent ) {
      $CardName, $SetNumber = if ( $ThisWantRow -match "\(" ) {
        $Name = $ThisWantRow -replace "^\d{1,3} (.*) \(.*",'$1'
        $SetNum = $ThisWantRow -replace ".*\) (.*)",'$1'

        <#
        Special printers (e.g. Foil, Extended Art)
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

    $WeHaveArray = @()
    foreach ( $ThisWantCard in $WantCardArray ) {
      $NameMatchArray = $InventoryArray.where{ $_.Name -match $ThisWantCard.Name }
      $OurStock = $NameMatchArray.where{ $_.Number -eq $ThisWantCard.Number }

      foreach ( $OurStockRow in $OurStock ) {
        if ( $OurStockRow.Qty -eq 0 ) {
          continue
        }

        Write-Verbose "Our condition: $($OurStockRow.Condition)"
        if ( ($ThisWantCard.Raw -match "\*F\*") -and ($OurStockRow.Condition -notmatch "Foil") ) {
          continue
        }

        $WeHaveArray += [PSCustomObject]@{
          Name        = $ThisWantCard.Name
          Set         = $OurStockRow.Set
          Condition   = $OurStockRow.Condition
          Quantity    = $OurStockRow.Qty
          Price       = $OurStockRow.OurPrice
          MarketValue = $OurStockRow.Market
          SetNumber   = $OurStockRow.Number
          Rarity      = $OurStockRow.Rarity
        }

      } # End block:foreach row from Our Stock

    } # End block:foreach Wanted Card from the Discord Order

    $DownloadsFolder = Join-Path $env:HOMEDRIVE (Join-Path $env:HOMEPATH "Downloads")

    $DateTImeStamp = (Get-Date).ToString( "DyyyyMMdd-THHmmss" )
    $FullDiscordCheckReport = Join-Path $DownloadsFolder ("DiscordOrderCheck-$($DateTImeStamp).csv")

    $WeHaveArray | Export-CSV -NTI -Path $FullDiscordCheckReport

    $WeHaveArray | Select-Object -Property Name, Set, Condition, Quantity

    <#
    Enhancement Idea

    export an updated Inventory CSV file that can be re-uploaded to TCG Player
    with the quantities correctly minus-d the pulled Discord Order cards

    .. to do that .. would need a step to confirm which exact sets (if multiple)
    were pulled for the Discorrd order
    #>

  } # End block:process

} # End function

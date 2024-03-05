<# RULER ----15--------25-----------------------50----------------------------80                 100                 120
Modified: 2024-03-05
By: Jackson B
#>
function New-DiscordOrder {
  [CmdletBinding()]

  param () # End block:param

  begin {
    function Write-Step ( [string[]]$Message ) {
      foreach ( $ThisStep in $Message ) {
        Write-Host $ThisStep
      }

      Write-Host ""
    } # End function:Write-Step

  } # End block:begin

  process {
    $ParamHash_Error = @{
      Message     = $null
      ErrorAction = "Stop"
    }

    $ProcessMsgArray = @(
      "Soon Windows file explorer will open",
      "1st: please select the TCG Player inventory export *.csv file",
      "2nd: please select the file containing the list of card(s) desired for the Discord order",
      "3rd: wait for the process to finish",
      ""
    )

    $PauseInSeconds = 0.5
    foreach ( $ThisLine in $ProcessMsgArray ) {
      Write-Host $ThisLine -ForegroundColor Green

      Start-Sleep -Milliseconds (1000 * $PauseInSeconds)

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

    $WantListContent = Get-Content $File.DiscordOrder.FullName

    Write-Step @(
      ("Discord Order Want List File: {0}" -f $File.DiscordOrder.Name),
      "",
      "Top several lines from the want list file"
    )

    foreach ( $ThisLine in $WantListContent[0 .. 5] ) {
      Write-Host $ThisLine
    }

    Write-Step @(
      "",
      ("Exported Inventory File: {0}" -f $File.TCGP.Name),
      ("Unique Inventory Count: {0:N0}" -f ($InventoryArray.Count - 1))
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

    Write-Step @(
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

    $DateTimeStamp = (Get-Date).ToString( "DyyyyMMdd-THHmmss" )
    $FullDiscordCheckReport = Join-Path $DownloadsFolder ("DiscordOrderCheck-$($DateTImeStamp).csv")

    if ( $WeHaveArray.Count -eq 0 ) {
      New-Item -ItemType File -Path $FullDiscordCheckReport | Out-Null
    } else {
      $WeHaveArray | Export-CSV -NTI -Path $FullDiscordCheckReport
    }

    Write-Step @(
      "DISCORD ORDER CHECK REPORT"
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

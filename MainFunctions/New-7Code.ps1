function New-RandomCode ( [int]$Len ) {
  $RandomAlphaNumericArray = @("A", "C", "E", "F", "G", "H", "J", "K", "P", "Q", "R", "S", "T", "X", "Y", "Z", "2", "3", "4", "5", "6", "7", "8", "9")

  $RandomCode = ""

  for ( $n = 0; $n -lt $Len; $n++ ) {
    $RandomCode += ($RandomAlphaNumericArray | Get-Random)

  } # End block:for the length of Random Code - add a random character

  Write-Output $RandomCode

} # End function:New-RandomCode

function New-7Code {
  $PreDash = New-RandomCode -Len 5
  $PostDash = New-RandomCode -Len 2

  $7Code = "{0}-{1}" -f $PreDash, $PostDash

  Write-Output $7Code

} # End function

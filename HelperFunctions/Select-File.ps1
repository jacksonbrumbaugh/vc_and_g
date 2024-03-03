<# RULER ----15--------25-----------------------50----------------------------80                 100                 120
Modified: 2024-03-03
By: Jackson B
#>
function Select-File {
  [CmdletBinding()]

  param (
    [string]
    $Title = "Select a file",

    [string]
    $InitialDirectory
  ) # End block:param

  begin {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
  } # End block:begin

  process {
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog

    <# a Get-Member of an OpenFileDialog
    Name                         MemberType
    ----                         ----------
    Disposed                     Event   
    FileOk                       Event   
    HelpRequest                  Event   

    CreateObjRef                 Method  
    Dispose                      Method  
    Equals                       Method  
    GetHashCode                  Method  
    GetLifetimeService           Method  
    GetType                      Method  
    InitializeLifetimeService    Method  
    OpenFile                     Method  
    Reset                        Method  
    ShowDialog                   Method  
    ToString                     Method  

    AddExtension                 Property
    AutoUpgradeEnabled           Property
    CheckFileExists              Property
    CheckPathExists              Property
    Container                    Property
    CustomPlaces                 Property
    DefaultExt                   Property
    DereferenceLinks             Property
    FileName                     Property
    FileNames                    Property
    Filter                       Property
    FilterIndex                  Property
    InitialDirectory             Property
    Multiselect                  Property
    ReadOnlyChecked              Property
    RestoreDirectory             Property
    SafeFileName                 Property
    SafeFileNames                Property
    ShowHelp                     Property
    ShowReadOnly                 Property
    Site                         Property
    SupportMultiDottedExtensions Property
    Tag                          Property
    Title                        Property
    ValidateNames                Property
    #>

    $OpenFileDialog.Title = $Title

    $OpenFileDialog.InitialDirectory = $InitialDirectory

    $OpenFileDialog.Filter = "All files (*.*)| *.*"

    $OpenFileDialog.ShowDialog() | Out-Null

    $SelectedFileName = $OpenFileDialog.Filename

    Write-Output $SelectedFileName

  } # End block:process

} # End function

function Add-ISEScriptParameter
{
 # Enter parameter(s) you want to use as default
 $paramText = Read-Host "Enter parameter(s) for $($psISE.CurrentFile.DisplayName)"
 
 # Create hash if not exists
 if (-not $Global:ISEScriptParamHash) { $Global:ISEScriptParamHash = @{} }
 
 # Add new parameters to the hash
 $Global:ISEScriptParamHash[$psISE.CurrentFile.FullPath] = $paramText
}
 
function Start-ISEScriptWithParameter
{
 # Find name of actual file name
 $File = $psISE.CurrentFile.FullPath
 
 # Run actual file with stored parameters
 Invoke-Expression -Command "$File $($Global:ISEScriptParamHash[$File])"
}
 
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('Add param', {Add-ISEScriptParameter}, 'Ctrl+Shift+F5')
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('Run with param', {Start-ISEScriptWithParameter}, 'Ctrl+F5')
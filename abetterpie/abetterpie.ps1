# +-----------------------------------------------------------------------------------------------------
# | File : abtterpie.ps1
# | Description : A PowerShell wrapper around piconfig, which allows the use of variables
# | Version : 0.1
# | Author : Jerome Lefebvre (OSIsoft)
# | Create Date : 2015-01-15
# | Modified Date: 2015-01-21
# | 
# +-----------------------------------------------------------------------------------------------------
# |  DISCLAIMER: This sample code is provided to members of the 
# |  PI Developers Club program (https://pisquare.osisoft.com/community/developers-club) 
# |  and is subject to the vCampus End-User License Agreement, found at 
# |  https://pisquare.osisoft.com/docs/DOC-1105.
# |  
# |  All sample code is provided by OSIsoft for illustrative purposes only.
# |  These examples have not been thoroughly tested under all conditions.
# |  OSIsoft provides no guarantee nor implies any reliability, 
# |  serviceability, or function of these programs.
# |  ALL PROGRAMS CONTAINED HEREIN ARE PROVIDED TO YOU "AS IS" 
# |  WITHOUT ANY WARRANTIES OF ANY KIND. ALL WARRANTIES INCLUDING 
# |  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY
# |  AND FITNESS FOR A PARTICULAR PURPOSE ARE EXPRESSLY DISCLAIMED.
# |  
# |  Please contact the PI Developers Club team at pidevclub@osisoft.com
# |  for questions or concerns regarding this sample code.
# +-----------------------------------------------------------------------------------------------------

<#
.SYNOPSIS
	Perform a given piconfig script and also adds basic variable functionality to piconnfig.
.DESCRIPTION
	Perform a given piconfig script and also adds basic variable functionality to piconnfig.
.PARAMETER PIConfigScript
	The name of the PI-Server, Script containig piconfig commands.
.PARAMETER PreserveInputFile
	Switch to indicate to preserve the input file used to execute the script.
.PARAMETER PreserveOutputFile
	Switch to indicate to preserve the output file used to execute the script.

.EXAMPLE	
C:\PS>$PIScript = @'
>>
>>@syst echo.
>>@syst echo Member Server Configuration ---------------------------------------------------
>>@syst echo Name,IsCurrentServer,ServerID,Collective,Description,FQDN,SyncPeriod,Role
>>@syst echo -------------------------------------------------------------------------------
>>@table pisys,piserver
>>@ostr name,iscurrentserver,serverid,collective,description,fqdn,syncperiod,role
>>@sele name=*
>>@ends
>>
>>'@

C:\PS>.\InvokePIConfigScript.ps1 $PIScript -pof

Description
-----------
This command executes a piconfig script and will keep the output returned by piconfig command. The
file can be found on the user profile temporary folder.

.EXAMPLE	
C:\PS>$PIScript = Get-Content -Path "c:\myPath\script1.dif" | Out-String
C:\PS>.\InvokePIConfigScript.ps1 $PIScript

Description
-----------
This command executes a piconfig script contained in a file.
#>

function GetDefaultPIServer {
	# A function that returns the default PIServer as listed in About-PI-SDK
	return (Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PISystem\PI-SDK\1.0).DefaultServer
}

function StringSlice($array, $slice) {
<#
Takes an array and a string that represents a slice
and returns the array after this slice has been applied.

For example:
$slice = "[2..5]"
$args = @(0,1,2,3,4,5,6)

$newargs = StringSlice -array $args -slice $slice
write-Host $newargs #writes 2 3 4 5

$slice = "[2..#len#]"
$args = @(0,1,2,3,4,5,6)

#>
	$array = $array | % { "`"$_`"" }
	$new = $array -join ","
	$new = "@($new)"
	Write-Host "$new$slice"
	if ($slice -match "#len#"){
		$length = $array.length
		$slice = $slice -replace  "#len#", "$length"
		Write-Host "Modified slice, $slice"
	}
	$newargs = invoke-expression "$new$slice"
	return $newargs
}

#region - Define private functions
# The following code comes from a script by Mathieu Hamel
# As posted here: https://pisquare.osisoft.com/message/40482
	function GetEnvVariable
	{
	[CmdletBinding(DefaultParameterSetName="Default", SupportsShouldProcess=$false)]
	param(
			[parameter(Mandatory=$true, Position=0, ParameterSetName = "Default")]
			[alias("vn")]
			[string]
			$VariableName,
			[parameter(Mandatory=$false, Position=1, ParameterSetName = "Default")]
			[alias("t")]
			[ValidateSet("Machine", "User", "Process")]
			[string]
			$Target = "Machine",
			[parameter(Mandatory=$false, ParameterSetName = "Default")]
			[string]
			$Computer = "")	
	
		try
		{
			if($Computer -eq "")
			{
				# Execute the GetEnvironmentVariable method locally or remotely via the Invoke-Command cmdlet.
				# Always use the Machine context to write the variable.
				$value = [Environment]::GetEnvironmentVariable($VariableName, $Target)
			}
			else
			{
				$scriptBlockCmd = [string]::Format("[Environment]::GetEnvironmentVariable(`"{0}`", `"{1}`")", $VariableName, $Target)
				$scriptBlock = [ScriptBlock]::create( $scriptBlockCmd )
				$value = Invoke-Command -ComputerName $Computer -ScriptBlock $scriptBlock
			}
			return $value
		}
		catch
		{
			# Return the error message.
			$msg1 = "A problem occurred during the reading of the environment variable: {0} from local machine." -f $_.Exception.Message
			$msg2 = "A problem occurred during the reading of the environment variable: {0} from {1} machine." -f $_.Exception.Message,$Computer
			if($Computer -eq "") { $msg = $msg1 } else { $msg = $msg2 }
			Throw [System.Exception] $msg
		}
	}	

	function ValidatePIConfigCLU
	{	
		try
		{
			# Set flags.
			$cluFound = $false

			# Get the PIHOME, PIHOME64 and PISERVER folders.
			$PIHome64_path = GetEnvVariable "PIHOME64" "Machine"
			$PIHome_path = GetEnvVariable "PIHOME" "Machine"
			$PIServer_path = GetEnvVariable "PISERVER" "Machine"
			$isPIServer = ($PIServer_path -ne $null)

			# Build all the possible paths.

			if(!([string]::IsNullOrEmpty($PIServer_path))) { $PIConfigExecSet1 = Join-Path -Path $PIServer_path -ChildPath "adm\piconfig.exe" }
			if(!([string]::IsNullOrEmpty($PIHome64_path))) { $PIConfigExecSet2 = Join-Path -Path $PIHome64_path -ChildPath "adm\piconfig.exe" }
			if(!([string]::IsNullOrEmpty($PIHome_path))) { $PIConfigExecSet3 = Join-Path -Path $PIHome_path -ChildPath "adm\piconfig.exe" }			

			# Validate where the piconfig CLUs are installed.
			# The piconfig.exe command is installed with PI SDK since version 1.4.0.416 on PINS

			# Test for the PISERVER variable.
			if($isPIServer -and ($cluFound -eq $false))
			{ if(Test-Path $PIConfigExecSet1) { $cluFound = $true; $PIConfigExec = $PIConfigExecSet1 } }

			# Test the 64-bit folder
			if($cluFound -eq $false)
			{ if(Test-Path $PIConfigExecSet2) { $cluFound = $true; $PIConfigExec = $PIConfigExecSet2 } }

			# Test the 32-bit folder
			if($cluFound -eq $false)
			{ if(Test-Path $PIConfigExecSet3) { $cluFound = $true; $PIConfigExec = $PIConfigExecSet3 } }

			# Throw error...
			if($cluFound -eq $false)
			{ $msg = "The module cannot find a piconfig.exe command-line utilities on this machine"; Throw [System.Exception] $msg }
			
			# Return the path.
			return $PIConfigExec
		}
		catch
		{ Throw }
	}
## End of the functions from Mathieu

function Piconfig-Path {
	$piconfigpath = ValidatePIConfigCLU
	$piconfigpath = "`"$piconfigpath`""
	$node = GetDefaultPIServer
	$piconfigpath = "$piconfigpath -Node $node -Trust"
	return $piconfigpath
}

function Run-Script($program) {
	# A function that calls a script stored in a string
	# It does so by storing the string into a temp file
	# which it later deletes
	# The output of piconfig is not captured

	# A library call to get a temporary file
	$tempfile = [System.IO.Path]::GetTempFileName()

	Set-Content $tempfile $program
	$piconfigpath = Piconfig-Path
	Write-Host  "$piconfigpath < $tempfile"
	cmd /c   "$piconfigpath < $tempfile"
	Write-Host $tempfile
	# Remove-Item $tempfile
}

## Get the betterpie arguments
# first the path of the abetterpie script
$file = $args[0]

# then all the arguments for that script
$vars = $args[1 .. ($args.count -1)]

## We now build out piconfig script
# starting from our template
$program = Get-Content $file

function getBracketContent ($line) {
	$r = [regex] "\[([^\[]*)\]"
	$match = $r.match($line)
	$text = $match.groups[1].value	
	$text = "[$text]"
	return $text
}

gitgit

if ($program -match "%i") {
	# replace the single line which has an %i
	$line = $program | Where-Object {$_ -match "%i"}

	Write-Host "line: $line"

	## To-DO check if brakcets are actually in the line
	$Bracket = getBracketContent($line)

	Write-Host $Bracket
	Write-Host "Vars: $vars" 
	$newvars = StringSlice -array $vars -slice $Bracket

	Write-Host "Newvars; $newvars"
	# Delete the brackets
	$lineWOBracket = $line -replace "\[([^\[]*)\]"
	Write-Host "line, without braket $lineWOBracket"

	$newlines =  $newvars | % {
		$lineWOBracket.replace("%i", $_)
	}

	Write-Host "New lines: $newlines"
	$new = $newlines -join "`r`n"
	Write-Host "New lines in the program, $new"
	$program = $program.replace($line, $new)
}

	# and adding in each variables given
	$counter = 0
	$vars | % {
		$program = $program -replace  "%$counter", $_
		$counter = $counter + 1
	}

Run-Script($program)

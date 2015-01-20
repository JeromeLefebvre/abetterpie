#
# abtterpie.ps1
# A powershell wrapper around piconfig, which allows the use of variables
#

Param (
	[string[]]$node = "localhost"
)

#region - Define private functions

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

			# Return the value found.
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

function Piconfig-Path($node="localhost") {
	$piconfigpath = ValidatePIConfigCLU
	$piconfigpath = "`"$piconfigpath`""
	$piconfigpath = "$piconfigpath -Node $node -Trust"
	return $piconfigpath
}

function Run-Script($program, $node="localhost") {
	# A function that calls a script stored in a string
	# It does so by storing the string into a temp file
	# which it later deletes
	# The output of piconfig is not captured

	# A library call to get a temporary file
	$tempfile = [System.IO.Path]::GetTempFileName()

	Set-Content $tempfile $program
	$piconfigpath = Piconfig-Path($node)
	Write-Host  "$piconfigpath < $tempfile"
	cmd /c   "$piconfigpath < $tempfile"
	# Write-Host $tempfile
	Remove-Item $tempfile
}

## Get the betterpie arguments
# first the path of the abetterpie script
$file = $args[0]

# then all the arguments for that script
$vars = $args[1 .. ($args.count -1)]

## We now build out piconfig script
# starting from our template
$program = Get-Content $file

if ($program -match "%i") {
	# replace the single line which has an %i
	$line = $program | Where-Object {$_ -match "%i"}

	$newlines =  $vars | % {
		$line.replace("%i", $_)
	}
	$new = $newlines -join "`r`n"
	$program = $program.replace($line, $new)
}
else {
	# and adding in each variables given
	$counter = 1
	$vars | % {
		$program = $program -replace  "%$counter", $_
		$counter = $counter + 1
	}
}

Run-Script($program) -node $node

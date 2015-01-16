#
# abtterpie.ps1
# A powershell wrapper around piconfig, which allows the use of variables
#
function Piconfig-Path {
	# Try to find where piconfig is
	# either in %piserver%
	if (Test-Path Env:piserver) {
		# Have to do a bit of a weird escaping here
		$piconfigpath = "`"$Env:piserver\adm\piconfig`""
	}
	# or %pihome%
	else {
		$piconfigpath = "`"$Env:pihome\adm\piconfig`""
	}
	# This is where you add any flags to piconfig you need to have
	# For example, here a node is specified and -Trust is the mode to log-in
	$piconfigpath = $piconfigpath + " -Node Jerome-PI1 -Trust"

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

Run-Script($program)

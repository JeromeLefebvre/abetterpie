
$counter = 0
while ($counter -le 5) {
	$counter = $counter + 1
	$val = [System.Math]::Sin($counter/10)
	.\abetterpie ".\examples\adddata.txt" randomtag $val
}

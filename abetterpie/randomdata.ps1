

$tagname = "fastsinusoid"
.\abetterpie  ".\examples\createTags.txt" $tagname

$counter = 0
while ($counter -le 1) {
	$counter = $counter + 1
	$val = [System.Math]::Sin($counter/10)
	.\abetterpie  ".\examples\adddata.txt" $tagname $val
}

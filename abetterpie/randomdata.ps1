

$tagname = "fastsinusoid2"
.\abetterpie -Node Jerome-PI1 ".\examples\createTags.txt" $tagname

$counter = 0
while ($counter -le 1) {
	$counter = $counter + 1
	$val = [System.Math]::Sin($counter/10)
	.\abetterpie -Node Jerome-PI1  ".\examples\adddata.txt" $tagname $val
}

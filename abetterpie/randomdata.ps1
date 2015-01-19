

$tagname = "fastsinusoid2"
.\abetterpie -Node localhost ".\examples\createTags.txt" $tagname

$counter = 0
while ($counter -le 1) {
	$counter = $counter + 1
	$val = [System.Math]::Sin($counter/10)
	.\abetterpie -Node localhost  ".\examples\adddata.txt" $tagname $val
}

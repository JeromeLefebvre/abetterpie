## About abetterpie

When I started learning about the PI system, I was using piconfig daily, but I often found a few things lacking about it. One of those things is the lack of variables. I've been thinking of an answer to this problem.

Here is a short introduction to abetterpie a piconfig wrapper written as a  PowerShell script.

## Generalities

One goal of abetterpie is that it would be a drop-in replacement for piconfig, thus all current piconfig scripts work with abetterpie.

Since abetterpie is written as a PowerShell script, in order to be able to use it, you must change the execution policy for the PowerShell command line. This is done by running the following command:

	Set-ExecutionPolicy　Unrestricted

More details can be read at: [Windows PowerShell の機能](http://technet.microsoft.com/ja-jp/library/ee176961.aspx)

For now, you cannot pass piconfig flags, for example -Trust or -Node, to abetterpie. Do pass on theses flags, you will need to modify the function Piconfig-Path in the abetterscript file.


## 変数のタイプ１
abetterpieの変数二つのタイプがあります。タイプ１は、%1、%2、%3などで書かれています。abetterpieのスクリプトを実行すると、%1はCLIで最初に書かれた引数に変わります。%2、%3などに同じふうに変更されます。

例えば

	@table pipoint
	@ostr tag
	@sele pointsource=%1
	@ends
というabetterpieのスクリプトを

	.\abetterpie select.txt opc

で実行したら、下記のPIconfigと同じように起動します。

	@table pipoint
	@ostr tag
	@sele pointsource=OPC
	@ends

## 変数のタイプ２
タイプ２は%iで書かれます。%iの意味は引数の全てを同じふうに拡大します。実行すると%iにある行は、引数の一つずつ同じ行に拡大します。

例えば

	@table pipoint
	@mode create
	@istr Tag, pointsource
	%i, OPC
	@ends

PowershellのCLIで

	.\abetterpie cdt1 cdt2 cdt3 cdt4

で実行したら、

	@table pipoint
	@mode create
	@istr Tag, pointsource
	cdt1, OPC
	cdt2, OPC
	cdt3, OPC
	cdt4, OPC
	@ends

と同じのpiconfigのスクリプトを実行します。

今では、変数タイプ１と変数タイプ２を混ぜれません。それとも、abetterpieのスクリプトの中にタイプ２は一回だけ使えます。

## 例、fastsinusoidのタグの作り方。

とりあえず、タグを作ります。

	@table pipoint
	@mode create
	@istr Tag, pointtype
	%i, float32
	@ends

そして、実行します。

	.\abetterpie .\examples\createtags.txt fastsinusoid

今、このタグに値を記入できるスクリプトを作成します。

	@table pisnap
	@mode edit, t
	@istr tag, time, value
	%1, *, %2
	@ends

下記の通りに実行できます。

		.\abetterpie .\examples\adddata.txt fastsinusoid 100

sinusoidのみたいのデータを欲しいから、PowerShellの数学の引数を使えます。

	$counter = 0
	while ($counter -ge 0) {
		$counter = $counter + 1
		$val = [System.Math]::Sin($counter/10)
		.\abetterpie .\examples\adddata.txt fastsinusoid $val
	}

確かに、Bufferingなどされていないし、インタフェースとして最悪ですが、早く書けるし、すぐ結果を出せるから、便利なスクリプトだと思います。
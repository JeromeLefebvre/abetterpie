## abetterpieについて

PIシステムの勉強し始めた時に、piconfigを毎日使いましたが、スクリプトを書くと機能では物足りないと考えました。その一つは変数がないということでした。その問題に対する回答にちょっと考えました。

PiconfigのラッパーのPowerShellスクリプトのabetterpieを紹介したいと思います。

## ラッパーについて

abetterpieの一つの目的はpiconfigの交換になります。つまり、今までのPiconfigのスクリプトをabetterpieでそのまま実行できます。
	二つの注意があります。abetterpieはPowerShellのスクリプトなので、実行できるためにSet-ExecutionPolicyというコマンドレットでPowerShellのスクリプトのポリシーを指定しなければなりません。PowerShellのコマンドラインインターフェース（CLI）で

	Set-ExecutionPolicy　Unrestricted
	
を実行するとのUnrestrictedの実行ポリシーが設定されます。詳しくは[Windows PowerShell の機能](http://technet.microsoft.com/ja-jp/library/ee176961.aspx)にご覧ください。

その上に、piconfigのパラメータを、「node」など、abetterpieでまだ使えません。piconfigのパラメータを使いたいなら、abetterpieのPiconfing-Pathという関数を変更しなければなりません。

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

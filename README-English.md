## About abetterpie

When I started learning about the PI system, I was using piconfig daily, but I often found a few things lacking about it. One of those things is the lack of variables. I've been thinking of an answer to this problem.

Here is a short introduction to abetterpie a piconfig wrapper written as a  PowerShell script.

## Generalities

One goal of abetterpie is that it would be a drop-in replacement for piconfig, thus all current piconfig scripts work with abetterpie.

Since abetterpie is written as a PowerShell script, in order to be able to use it, you must change the execution policy for the PowerShell command line. This is done by running the following command:

	Set-ExecutionPolicy　Unrestricted

More details can be read at: [Windows PowerShell の機能](http://technet.microsoft.com/ja-jp/library/ee176961.aspx)

For now, you cannot pass piconfig flags, for example -Trust or -Node, to abetterpie. Do pass on theses flags, you will need to modify the function Piconfig-Path in the abetterscript file.


## Variables of type 1
abetterpie has two types of variables. The first time, is written of the form %1, %2, %3, etc. At execution time, theses variables are expanded along with the arguments given at the command line.

For example if the following abetterpie script:

	@table pipoint
	@ostr tag
	@sele pointsource=%1
	@ends

is ran using the command:

	.\abetterpie select.txt opc

it will run as the following piconfig script:

	@table pipoint
	@ostr tag
	@sele pointsource=OPC
	@ends

## Variable type 2
The second type of variable is written as %i. %i stands for all variables and the way it is expanded is that it will repeat the line where %i, with %i replaced by all the given arguments.

For example, if the following script:

	@table pipoint
	@mode create
	@istr Tag, pointsource
	%i, OPC
	@ends

is ran as:

	.\abetterpie cdt1 cdt2 cdt3 cdt4

it will execute as the following piconfig script:

	@table pipoint
	@mode create
	@istr Tag, pointsource
	cdt1, OPC
	cdt2, OPC
	cdt3, OPC
	cdt4, OPC
	@ends

For now, type 1 and type 2 cannot be mixed in the same script.


## Example, let's create a fastsinusoid tag.

Let's first create our tag:

	@table pipoint
	@mode create
	@istr Tag, pointtype
	%i, float32
	@ends

which we run as:

	.\abetterpie .\examples\createtags.txt fastsinusoid

Then, we need a script that can add values to the Data Archive:

	@table pisnap
	@mode edit, t
	@istr tag, time, value
	%1, *, %2
	@ends

Which we can run as follows:

		.\abetterpie .\examples\adddata.txt fastsinusoid 100

Since, we are recreating a sinusoid like tag, we can PowerShell's math library's functionality as follows:

	$counter = 0
	while ($counter -ge 0) {
		$counter = $counter + 1
		$val = [System.Math]::Sin($counter/10)
		.\abetterpie .\examples\adddata.txt fastsinusoid $val
	}

In a sense, this is the world's worst interface. But, how quickly it can be written, gives it some usefulness.
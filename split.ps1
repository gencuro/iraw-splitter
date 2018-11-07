function Find-Pattern
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		$src,
		[Parameter(Mandatory)]
		$pattern
	)

	$size = $src.Length - $pattern.Length + 1

	$j = 0

	for ($i = 0; $i -lt $size; $i++)
	{
		if ($src[$i] -ne $pattern[0])
		{
			continue
		}

		for ($j = $pattern.Length - 1; $j -ge 1 -and $src[$i + $j] -eq $pattern[$j]; $j--) 
		{
		}


		if ($j -eq 0)
		{
			return $i
		}
	}

	return -1
}

$filePath = $null
$filePath = $args[0]

#$filePath = 'E:\Projects\iraw\test.iraw'

if ($filePath -eq $null)
{
	Write-Host -NoNewLine 'Need to specify file with images.'
	exit
}


$source = New-Object -TypeName System.IO.FileStream -ArgumentList $filePath, 'Open'

$sourceLen = $source.Length

#$pattern = [System.Text.Encoding]::ASCII.GetBytes('PNG')
$pattern = [byte[]](0x89, 0x50, 0x4E, 0x47) #Need to take in account 0x89 otherwise some images could be wrong.

$target = $null

$processedSize = 0

$file = 0

while ($processedSize -lt $sourceLen)
{

	$blockSize = If (($processedSize + 1024) -lt $sourceLen) {1024} Else {$sourceLen - $processedSize}

	$processedSize += $blockSize

	$buffer = [System.Byte[]]::CreateInstance([System.Byte], $blockSize)
		
	$readSize = $source.Read($buffer, 0, $blockSize)

	$idx = Find-Pattern $buffer $pattern
	
	if ($idx -ne -1)
	{
		if ($target -eq $null)
		{
			$target = New-Object -TypeName System.IO.FileStream -ArgumentList ($filePath + $file + '.png'), 'Create', 'Write'
		}
		else
		{
			$target.Write($buffer, 0, $idx);
			$target.Close()

			$target = New-Object -TypeName System.IO.FileStream -ArgumentList ($filePath + $file + '.png'), 'Create', 'Write'
		}

		$file++

		Write-Host -NoNewLine "File = " $file

		$target.Write($buffer, $idx, $blockSize - $idx);
	}
	elseif ($target -ne $null)
	{
		$target.Write($buffer, 0, $blockSize);
	}
}

if ($target -ne $null)
{
	$target.Close
	$target = $null
}

$source.Close

Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
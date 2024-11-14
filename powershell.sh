$sourceFilea = "path\to\5GBfile.txt"  # Replace with the path to your 5GB file
$destinationFile = "path\to\largefile.txt"  # Replace with the desired path for the larger file
$numCopies = 3  # Adjust this number to control the final size

Copy-Item $sourceFile $destinationFile
for ($i = 1; $i -lt $numCopies; $i++) {
    Add-Content $destinationFile -Value (Get-Content $sourceFile -ReadCount 0)
}
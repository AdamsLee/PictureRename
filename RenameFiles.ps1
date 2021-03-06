param($path2Rename = "D:\Temp")

# Load the assemblies needed for reading and parsing EXIF
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") > $null
[System.Reflection.Assembly]::LoadWithPartialName("System.Text") > $null

function Gen-FileName($parent, $newfile)
{
    $i = 1
    $tempname = $newfile
    while(Test-Path (Join-Path $parent $tempname))
    {
        $tempname = $newfile.Substring(0,19) + "-$i" + $newfile.Substring(19,4)
        $i++
    }
    $tempname
}


$getTakenHourTime = { 
    $extension = $_.Extension
    Write-Host "Analyzing " $_.FullName
    if($extension -eq ".jpg")
    {
        $photo = [System.Drawing.Image]::FromFile($_.FullName)
        try
        {
            $dateProp = $photo.GetPropertyItem(36867)
        }
        catch
        {
            try
            {
                $dateProp = $photo.GetPropertyItem(306)
            }
            catch
            {
                continue
            }
        }
        $photo.Dispose()
        
        # Convert date taken metadata to appropriate fields
        $encoding = New-Object System.Text.UTF8Encoding
        $date = $encoding.GetString($dateProp.Value).Trim()
        $year = $date.Substring(0,4)
        $month = $date.Substring(5,2)
        $day = $date.Substring(8,2)
        $hour = $date.Substring(11,2)

        $filename = "$year-$month-$day $hour"
    }
    else
    {
        $year = $_.LastWriteTime.Year.ToString()
        $month = $_.LastWriteTime.Month.ToString("D2")
        $day = $_.LastWriteTime.Day.ToString("D2")
        $hour = $_.LastWriteTime.Hour.ToString("D2")
        $filename = "$year-$month-$day $hour"
    }
    $filename
}

$getTakenTime4FileName = { 
    $extension = $_.Extension
    if($extension -eq ".jpg")
    {
        $photo = [System.Drawing.Image]::FromFile($_.FullName)
        try
        {
            $dateProp = $photo.GetPropertyItem(36867)
        }
        catch
        {
            try
            {
                $dateProp = $photo.GetPropertyItem(306)
            }
            catch
            {
                continue
            }
        }
        $photo.Dispose()
        
        # Convert date taken metadata to appropriate fields
        $encoding = New-Object System.Text.UTF8Encoding
        $date = $encoding.GetString($dateProp.Value).Trim()
        $year = $date.Substring(0,4)
        $month = $date.Substring(5,2)
        $day = $date.Substring(8,2)
        $hour = $date.Substring(11,2)
        $min = $date.Substring(14,2)
        $sec = $_.LastWriteTime.Second.ToString("D2")

        $filename = "$year-$month-$day $hour.$min.$sec$extension"
    }
    else
    {
        $year = $_.LastWriteTime.Year.ToString()
        $month = $_.LastWriteTime.Month.ToString("D2")
        $day = $_.LastWriteTime.Day.ToString("D2")
        $hour = $_.LastWriteTime.Hour.ToString("D2")
        $min = $_.LastWriteTime.Minute.ToString("D2")
        $sec = $_.LastWriteTime.Second.ToString("D2")
        $filename = "$year-$month-$day $hour.$min.$sec$extension"
    }
    Gen-FileName $_.DirectoryName $filename
}

get-childitem –path $path2Rename -Recurse -Include *.jpg,*.mov | `
where { $_.Name.Length -le 13 -or ((Invoke-Command -ScriptBlock $getTakenHourTime) -ne $_.Name.Substring(0, 13)) } | `
% {Write-Host $_.FullName " can be renamed to new name " (Invoke-Command -ScriptBlock $getTakenTime4FileName)}

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Rename files"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not rename files"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$result = $host.ui.PromptForChoice("", "Rename files?", $options, 0) 

if(!$result)
{
    get-childitem –path $path2Rename -Recurse -Include *.jpg,*.mov | `
    where { $_.Name.Length -le 13 -or ((Invoke-Command -ScriptBlock $getTakenHourTime) -ne $_.Name.Substring(0, 13)) } | `
    Rename-Item -NewName $getTakenTime4FileName

    Write-Host "Processing Complete"
}
else
{
    Write-Host "Exit without renaming files"
}
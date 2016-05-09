function Load-XAML
{
Param(
 [parameter(Mandatory=$True,Position=1)]
 [string]$XAMLPath
)

$ImageSource = 'Source="' + "$((gci -Directory | ?{$_.Name -eq "Images"}).FullName)\"

## Loads XML and removes unnecessary items
$XAML = (Get-Content -Path $XAMLPath) -replace 'Source="','Source="[$ImageDir]' -replace 'Icon="','Icon="[$ImageDir]'
[xml]$Global:xmlWPF = $(Get-Content -Path $XAMLPath) -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*','<Window' -replace 'Source="',$ImageSource -replace 'Icon="',$ImageSource

## Add WPF and Windows Forms assemblies
try
{
    Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,system.windows.forms
} 
catch 
{
 Throw "Failed to load WPF."
} 

## Create the XAML reader using XML node reader
$Global:GUI = [Windows.Markup.XamlReader]::Load((new-object System.Xml.XmlNodeReader $xmlWPF))

## Create objects based on XAML Name
$xmlWPF.SelectNodes("//*[@Name]") | %{Set-Variable -Name ($_.Name) -Value $GUI.FindName($_.Name) -Scope Global}
}
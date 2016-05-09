<#
.SYNOPSIS

Play PS Invaders!

.DESCRIPTION

This was built for a demo at the Automation Management Summit 2016 (ams2016.com) as an example of using XAML and PowerShell to create tools for enterprise use.

.EXAMPLE

.\Play-PSInvaders.ps1

.NOTES

Play-PSInvaders.ps1, Load-XAML.ps1, and MainWindow.xaml are all required and should be in the same directory. 
You also need directories named "Sounds" and "Images" at the same level as the scripts, containing your .wav and images respectively.

Created by Jesse Walter, Model Technology Solutions
April 28, 2016

.LINK

https://github.com/jessewalter/EssentiallyNon-Essential/tree/master/PSInvaders

www.model-technology.com

#>

Set-Location $PSScriptRoot

#region Load Game
. .\Load-XAML.ps1

$XAMLPath = (gci -filter "MainWindow.xaml").FullName

Load-XAML $XAMLPath
#endregion

#region Default Variables
$script:array = @($invader1,$invader2,$invader3,$invader4,$invader5,$invader6,$invader7,$invader8,$invader9,$invader10,$invader11,$invader12,$invader13,$invader14)
$move = 'right'
$starttext.Visibility = 'Visible'

## Sounds
$SoundsDir = (gci -Directory | ?{$_.Name -eq 'Sounds'}).FullName
$sound_start = New-Object System.Media.SoundPlayer "$SoundsDir\start.wav"
$sound_missile = New-Object System.Media.SoundPlayer "$SoundsDir\missile.wav"
$sound_invaderdead = New-Object System.Media.SoundPlayer "$SoundsDir\invaderdead.wav"
$sound_explode = New-Object System.Media.SoundPlayer "$SoundsDir\explode.wav"
$sound_pew = New-Object System.Media.SoundPlayer "$SoundsDir\pew.wav"
$sound_tada = New-Object System.Media.SoundPlayer "$SoundsDir\tada.wav"
#endregion

#region Timer Controls
$start_timer = New-Object System.Windows.Threading.DispatcherTimer
$start_timer.Interval = [timespan]"0:0:1"
$invader_timer = New-Object System.Windows.Threading.DispatcherTimer
$invader_timer.Interval = [timespan]"0:0:0.0075"
$fire1_timer = New-Object System.Windows.Threading.DispatcherTimer
$fire1_timer.Interval = [timespan]"0:0:0.0075"
$fire2_timer = New-Object System.Windows.Threading.DispatcherTimer
$fire2_timer.Interval = [timespan]"0:0:0.0075"
$randomfire_timer= New-Object System.Windows.Threading.DispatcherTimer
$randomfire_timer.Interval = [timespan]"0:0:1.0"
$resetsprite_timer = New-Object System.Windows.Threading.DispatcherTimer
$resetsprite_timer.Interval = [timespan]"0:0:1"

$invader_timer.Add_Tick({
    if ($move -eq 'right')
    {
        ForEach ($invader in $array)
        {
            Set-SpriteLoc $invader $($invader.Margin.Left + 1) $($invader.Margin.Top) $($invader.Margin.Right) $($invader.Margin.Bottom)
        }
    }
    elseif ($move -eq 'left')
    {
        ForEach ($invader in $array)
        {
            Set-SpriteLoc $invader $($invader.Margin.Left - 1) $($invader.Margin.Top) $($invader.Margin.Right) $($invader.Margin.Bottom)
        }
    }
    elseif ($move -eq 'down')
    {
        ForEach ($invader in $array)
        {
            Set-SpriteLoc $invader $($invader.Margin.Left) $($invader.Margin.Top + 20) $($invader.Margin.Right) $($invader.Margin.Bottom)
        }
    }
})

$start_timer.Add_Tick({
    if ($starttext.Visibility -eq 'Visible')
    {
        $starttext.Visibility = 'Hidden'
    }
    else
    {
        $starttext.Visibility = 'Visible'
    }
})

$fire1_timer.Add_Tick({
    $Fire1.Margin = "$($Fire1.Margin.Left),$($Fire1.Margin.Top - 10),0,0"
    if ($Fire1.Margin.Top -gt 0)
    {
        ForEach ($invader in $array)
        {
            if ($invader.Visibility -eq 'Visible' -and $Fire1.Margin.Top -le ($invader.Margin.Top + $invader.ActualHeight) -and ($Fire1.Margin.Left -ge $invader.Margin.Left -and $Fire1.Margin.Left -le ($invader.Margin.Left + $invader.ActualWidth)))
            {
                $sound_invaderdead.Play()
                $Fire1.Visibility = 'Collapsed'
                $fire1_timer.Stop()
                $invader.Visibility = 'Collapsed'
                $script:score = $score + 100
                $scoredisplay.Content = "{0:D5}" -f $score
                $levelclear = $array | ?{$_.Visibility -eq 'Collapsed'}
                if ($levelclear.count -eq $array.count)
                {
                    Set-InvaderLoc
                    $sound_tada.Play()
                    $script:level = $level + 1
                    $leveldisplay.Content = $level
                }
            }
        }
    }
    else
    {
        $Fire1.Visibility = 'Collapsed'
        $fire1_timer.Stop()
    }
})

$fire2_timer.Add_Tick({
    $Fire2.Margin = "$($Fire2.Margin.Left),$($Fire2.Margin.Top + 10),0,0"
    if ($Fire2.Margin.Top -le $background.Height)
    {
        if ($pssprite.Visibility -eq 'Visible' -and ($Fire2.Margin.Top + $Fire2.Height) -ge $pssprite.Margin.Top -and ($Fire2.Margin.Left -ge $pssprite.Margin.Left -and $Fire2.Margin.Left -le ($pssprite.Margin.Left + $pssprite.ActualWidth)))
        {
            $script:lives = $lives - 1
            $livesdisplay.Content = $lives
            $sound_explode.Play()
            $randomfire_timer.Stop()
            $fire2_timer.Stop()
            $Fire2.Visibility = 'Collapsed'
            $explosion.Margin = $pssprite.Margin
            $pssprite.Visibility = 'Collapsed'
            $explosion.Visibility = 'Visible'
            $invader_timer.Stop()
            if ($lives -gt 0)
            {
                $resetsprite_timer.start()
            }
            else
            {
                $starttext.Visibility = 'Visible'
                $starttext.Content = 'GAME OVER'
            }
        }
    }
    else
    {
        $Fire2.Visibility = 'Collapsed'
        $fire2_timer.Stop()
    }
})

$randomfire_timer.Add_Tick({
    Fire-AlienCannon
})

$resetsprite_timer.Add_Tick({
    if ($starttext.Visibility -eq 'Collapsed' -and $starttext.Content -ne 'READY?')
    {
        $starttext.FontSize = 30
        $starttext.Content = 'READY?'
        $starttext.Visibility = 'Visible'
    }
    elseif ($starttext.Visibility -eq 'Visible' -and $starttext.Content -eq 'READY?')
    {
        $starttext.Visibility = 'Hidden'
        $starttext.FontSize = 46
        $starttext.Content = 'GO!'
    }
    elseif ($starttext.Visibility -eq 'Hidden' -and $starttext.Content -eq 'GO!')
    {
        $starttext.Visibility = 'Visible'
    }
    elseif ($starttext.Visibility -eq 'Visible' -and $starttext.Content -eq 'GO!')
    {
        $starttext.Visibility = 'Collapsed'
        $explosion.Visibility = 'Collapsed'
        Set-SpriteLoc $pssprite $($background.ActualWidth / 2) $($background.ActualHeight - $pssprite.Height) 0 0; $pssprite.Visibility = 'Visible'
        $invader_timer.Start()
        $randomfire_timer.Start()
        $resetsprite_timer.Stop()
    }
})

$GUI.Add_Closing({
    $fire1_timer.Stop()
    $fire2_timer.Stop()
    $randomfire_timer.Stop()
    $invader_timer.Stop()
    $start_timer.Stop()
    $resetsprite_timer.Stop()
})
#endregion

#region Functions
function Set-SpriteLoc ($sprite,$x,$y,$x0,$y0)
{
    $sprite.Margin = "$x,$y,$x0,$y0"
    if ($($sprite.Margin.Left + $sprite.ActualWidth) -ge $($background.ActualWidth))
    {
        if ($sprite.name -ne 'pssprite')
        {
            $sprite.Margin = "$x,$y,$x0,$y0"
            if ($script:move -ne 'down')
            {
                $script:move = 'down'
            }
            else
            {
                $script:move = 'left'
            }
        }
        else
        {
            $sprite.Margin = "$($x - 10),$y,$x0,$y0"
        }
    }
    if ($($sprite.Margin.Left) -le $($background.Margin.Left))
    {
        if ($sprite.name -ne 'pssprite')
        {
            $sprite.Margin = "$x,$y,$x0,$y0"
            if ($script:move -ne 'down')
            {
                $script:move = 'down'
            }
            else
            {
                $script:move = 'right'
            }
        }
        else
        {
            $sprite.Margin = "$($x + 10),$y,$x0,$y0"
        }
    }
}

function Set-InvaderLoc
{
    Set-SpriteLoc $invader1 $($background.Margin.Left) $($background.Margin.Top + 40) 0 0; $invader1.Visibility = 'Visible'
    Set-SpriteLoc $invader2 $($invader1.Margin.left + $invader1.ActualWidth + 10) $($background.Margin.Top + 40) 0 0; $invader2.Visibility = 'Visible'
    Set-SpriteLoc $invader3 $($invader2.Margin.left + $invader2.ActualWidth + 10) $($background.Margin.Top + 40) 0 0; $invader3.Visibility = 'Visible'
    Set-SpriteLoc $invader4 $($invader3.Margin.left + $invader3.ActualWidth + 10) $($background.Margin.Top + 40) 0 0; $invader4.Visibility = 'Visible'
    Set-SpriteLoc $invader5 $($invader4.Margin.left + $invader4.ActualWidth + 10) $($background.Margin.Top + 40) 0 0; $invader5.Visibility = 'Visible'
    Set-SpriteLoc $invader6 $($invader5.Margin.left + $invader5.ActualWidth + 10) $($background.Margin.Top + 40) 0 0; $invader6.Visibility = 'Visible'
    Set-SpriteLoc $invader7 $($invader6.Margin.left + $invader6.ActualWidth + 10) $($background.Margin.Top + 40) 0 0; $invader7.Visibility = 'Visible'

    Set-SpriteLoc $invader8 $($invader1.Margin.Left + $($invader1.ActualWidth / 2)) $($invader1.ActualHeight + $invader1.Margin.Top + 10) 0 0; $invader8.Visibility = 'Visible'
    Set-SpriteLoc $invader9 $($invader8.Margin.left + $invader8.ActualWidth + 10) $($invader8.Margin.Top) 0 0; $invader9.Visibility = 'Visible'
    Set-SpriteLoc $invader10 $($invader9.Margin.left + $invader9.ActualWidth + 10) $($invader9.Margin.Top) 0 0; $invader10.Visibility = 'Visible'
    Set-SpriteLoc $invader11 $($invader10.Margin.left + $invader10.ActualWidth + 10) $($invader10.Margin.Top) 0 0; $invader11.Visibility = 'Visible'
    Set-SpriteLoc $invader12 $($invader11.Margin.left + $invader11.ActualWidth + 10) $($invader11.Margin.Top) 0 0; $invader12.Visibility = 'Visible'
    Set-SpriteLoc $invader13 $($invader12.Margin.left + $invader12.ActualWidth + 10) $($invader12.Margin.Top) 0 0; $invader13.Visibility = 'Visible'
    Set-SpriteLoc $invader14 $($invader13.Margin.left + $invader13.ActualWidth + 10) $($invader13.Margin.Top) 0 0; $invader14.Visibility = 'Visible'
}

function Fire-ShooterCannon
{
    $Fire1.Margin = "$($pssprite.Margin.Left + $($pssprite.ActualWidth / 2)),$($pssprite.Margin.Top),0,0"
    $Fire1.Visibility = 'Visible'
    $sound_pew.Play()
}

function Fire-AlienCannon
{
    $shooter = $array | Get-Random
    if ($shooter.Visibility -eq 'Visible')
    {
        
        $Fire2.Margin = "$($shooter.Margin.Left + $($shooter.ActualWidth / 2)),$($shooter.Margin.Top + $shooter.Height),0,0"
        $fire2_timer.Start()
        $Fire2.Visibility = 'Visible'
    }
}

function Reset-PSShooter
{
    
    $resetsprite_timer.Start()
}
#endregion

#region Event Handlers
$GUI.Add_KeyDown(
{
    if ($_.Key -eq "enter")
    {
## Clear screen and kill original timer
        $title.Visibility = 'Collapsed'
        $title_shadow.Visibility = 'Collapsed'
        $starttext.Visibility = 'Collapsed'
        $start_timer.Stop()
        $explosion.Visibility = 'Collapsed'

## Set counts
        $script:lives = 3
        $script:score = 0
        $script:level = 1

## Add lives and score visibility
        $pssprite.Visibility = 'Visible'
        $livestext.Visibility = 'Visible'
        $scoretext.Visibility = 'Visible'
        $leveltext.Visibility = 'Visible'
        $livesdisplay.Content = $lives
        $livesdisplay.Visibility = 'Visible'
        $scoredisplay.Content = "{0:D5}" -f $score
        $scoredisplay.Visibility = 'Visible'
        $leveldisplay.Content = $level
        $leveldisplay.Visibility = 'Visible'

## Set starting sprite location and make visible
        Set-SpriteLoc $pssprite $($background.ActualWidth / 2) $($background.ActualHeight - $pssprite.Height) 0 0; $pssprite.Visibility = 'Visible'
        Set-InvaderLoc

        $invader_timer.Start()
        $randomfire_timer.Start()
    }
})
#endregion

#region Controls
$GUI.Add_KeyDown({if ($_.Key -eq "left"){Set-SpriteLoc $pssprite $($pssprite.Margin.Left - 10) $pssprite.Margin.Top $pssprite.Margin.Right $pssprite.Margin.Bottom}})
$GUI.Add_KeyDown({if ($_.Key -eq "right"){Set-SpriteLoc $pssprite $($pssprite.Margin.Left + 10) $pssprite.Margin.Top $pssprite.Margin.Right $pssprite.Margin.Bottom}})
$GUI.Add_KeyDown({if ($_.Key -eq "space"){Fire-ShooterCannon;$fire1_timer.Start()}})
$GUI.Add_KeyDown({if ($_.Key -eq "esc"){$GUI.Close();[System.GC]::Collect()}})
#endregion

#region Show Window
$start_timer.Start()
$sound_start.Play()
$GUI.ShowDialog() | Out-Null
#endregion

#region Clean up
Remove-Variable * -ErrorAction SilentlyContinue
[System.GC]::Collect()
#endregion
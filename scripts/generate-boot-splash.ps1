param(
  [Parameter(Mandatory = $true)]
  [string]$OutputPath,

  [string]$SourceImagePath = "",

  [switch]$RemoveDesktopLogo,

  [switch]$AddHeaderText,

  [int]$Width = 640,
  [int]$Height = 480
)

Add-Type -AssemblyName System.Drawing

$outputDir = Split-Path -Parent $OutputPath
if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
  New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$bitmap = New-Object System.Drawing.Bitmap $Width, $Height, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

function Copy-ScaledWallpaper {
  param(
    [System.Drawing.Graphics]$TargetGraphics,
    [string]$ImagePath,
    [int]$TargetWidth,
    [int]$TargetHeight
  )

  $source = [System.Drawing.Image]::FromFile((Resolve-Path -LiteralPath $ImagePath))
  try {
    $sourceRatio = $source.Width / $source.Height
    $targetRatio = $TargetWidth / $TargetHeight

    if ($sourceRatio -gt $targetRatio) {
      $cropHeight = $source.Height
      $cropWidth = [int]($source.Height * $targetRatio)
      $cropX = [int](($source.Width - $cropWidth) / 2)
      $cropY = 0
    } else {
      $cropWidth = $source.Width
      $cropHeight = [int]($source.Width / $targetRatio)
      $cropX = 0
      $cropY = [int](($source.Height - $cropHeight) / 2)
    }

    $sourceRect = New-Object System.Drawing.Rectangle $cropX, $cropY, $cropWidth, $cropHeight
    $targetRect = New-Object System.Drawing.Rectangle 0, 0, $TargetWidth, $TargetHeight
    $TargetGraphics.DrawImage($source, $targetRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
  } finally {
    $source.Dispose()
  }
}

function Remove-CenteredDesktopLogo {
  param(
    [System.Drawing.Bitmap]$TargetBitmap,
    [int]$TargetWidth,
    [int]$TargetHeight
  )

  throw "RemoveDesktopLogo is disabled: use a logo-free SourceImagePath for a clean boot splash."
}

function Draw-HeaderText {
  param(
    [System.Drawing.Graphics]$TargetGraphics,
    [int]$TargetWidth,
    [int]$TargetHeight
  )

  $textX = [Math]::Round($TargetWidth * 0.32)
  $titleY = [Math]::Round($TargetHeight * 0.13)
  $titleSize = [Math]::Max(28, [Math]::Round($TargetWidth * 0.047))
  $subSize = [Math]::Max(16, [Math]::Round($TargetWidth * 0.025))
  $lineSize = [Math]::Max(14, [Math]::Round($TargetWidth * 0.021))

  $fontTitle = New-Object System.Drawing.Font "Segoe UI", $titleSize, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
  $fontSub = New-Object System.Drawing.Font "Segoe UI", $subSize, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
  $fontLine = New-Object System.Drawing.Font "Segoe UI", $lineSize, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)

  $shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(190, 0, 0, 0))
  $whiteBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(248, 250, 255, 255))
  $cyanBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 101, 255, 247))

  try {
    $TargetGraphics.DrawString("Devworks Server OS", $fontTitle, $shadowBrush, $textX + 2, $titleY + 2)
    $TargetGraphics.DrawString("Devworks Server OS", $fontTitle, $whiteBrush, $textX, $titleY)
    $TargetGraphics.DrawString("v0.2.1 Dual Boot Hardware", $fontSub, $shadowBrush, $textX + 1, $titleY + [Math]::Round($titleSize * 1.25) + 1)
    $TargetGraphics.DrawString("v0.2.1 Dual Boot Hardware", $fontSub, $cyanBrush, $textX, $titleY + [Math]::Round($titleSize * 1.25))
    $TargetGraphics.DrawString("Installer permanen | GUI native | monitoring server", $fontLine, $shadowBrush, $textX + 1, $titleY + [Math]::Round($titleSize * 2.05) + 1)
    $TargetGraphics.DrawString("Installer permanen | GUI native | monitoring server", $fontLine, $whiteBrush, $textX, $titleY + [Math]::Round($titleSize * 2.05))
  } finally {
    $shadowBrush.Dispose()
    $whiteBrush.Dispose()
    $cyanBrush.Dispose()
    $fontTitle.Dispose()
    $fontSub.Dispose()
    $fontLine.Dispose()
  }
}

try {
  $rect = New-Object System.Drawing.Rectangle 0, 0, $Width, $Height

  if ($SourceImagePath) {
    Copy-ScaledWallpaper -TargetGraphics $graphics -ImagePath $SourceImagePath -TargetWidth $Width -TargetHeight $Height
    if ($RemoveDesktopLogo) {
      Remove-CenteredDesktopLogo -TargetBitmap $bitmap -TargetWidth $Width -TargetHeight $Height
    }
  } else {
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
      $rect,
      [System.Drawing.Color]::FromArgb(5, 25, 43),
      [System.Drawing.Color]::FromArgb(8, 47, 75),
      0.0
    )
    $graphics.FillRectangle($bg, $rect)
    $bg.Dispose()
  }

  if ($AddHeaderText) {
    Draw-HeaderText -TargetGraphics $graphics -TargetWidth $Width -TargetHeight $Height
  }

  $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
  $graphics.Dispose()
  $bitmap.Dispose()
}

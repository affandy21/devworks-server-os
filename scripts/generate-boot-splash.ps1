param(
  [Parameter(Mandatory = $true)]
  [string]$OutputPath,

  [string]$SourceImagePath = "",

  [switch]$RemoveDesktopLogo,

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

  $x1 = [Math]::Max(0, [int]($TargetWidth * 0.445))
  $x2 = [Math]::Min($TargetWidth - 1, [int]($TargetWidth * 0.555))
  $y1 = [Math]::Max(0, [int]($TargetHeight * 0.425))
  $y2 = [Math]::Min($TargetHeight - 1, [int]($TargetHeight * 0.575))
  $sampleOffset = [Math]::Max(18, [int]($TargetHeight * 0.18))

  for ($pass = 0; $pass -lt 3; $pass++) {
    for ($y = $y1; $y -le $y2; $y++) {
      for ($x = $x1; $x -le $x2; $x++) {
        $sx = $x
        $sy = [Math]::Max(0, $y - $sampleOffset)
        $left = $TargetBitmap.GetPixel([Math]::Max(0, $x1 - 8), $y)
        $right = $TargetBitmap.GetPixel([Math]::Min($TargetWidth - 1, $x2 + 8), $y)
        $top = $TargetBitmap.GetPixel($sx, $sy)
        $bottom = $TargetBitmap.GetPixel($sx, [Math]::Min($TargetHeight - 1, $y2 + 8))
        $horizontal = ($x - $x1) / [Math]::Max(1, ($x2 - $x1))

        $r = [int]((($left.R * (1 - $horizontal)) + ($right.R * $horizontal) + $top.R + $bottom.R) / 3)
        $g = [int]((($left.G * (1 - $horizontal)) + ($right.G * $horizontal) + $top.G + $bottom.G) / 3)
        $b = [int]((($left.B * (1 - $horizontal)) + ($right.B * $horizontal) + $top.B + $bottom.B) / 3)

        $TargetBitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($r, $g, $b))
      }
    }
  }

  $blur = [System.Drawing.Graphics]::FromImage($TargetBitmap)
  try {
    $blur.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $blur.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $src = New-Object System.Drawing.Rectangle $x1, $y1, ($x2 - $x1 + 1), ($y2 - $y1 + 1)
    $small = New-Object System.Drawing.Bitmap ([Math]::Max(1, [int]($src.Width / 8))), ([Math]::Max(1, [int]($src.Height / 8)))
    $smallGraphics = [System.Drawing.Graphics]::FromImage($small)
    try {
      $smallGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $smallGraphics.DrawImage($TargetBitmap, (New-Object System.Drawing.Rectangle 0, 0, $small.Width, $small.Height), $src, [System.Drawing.GraphicsUnit]::Pixel)
      $blur.DrawImage($small, $src, (New-Object System.Drawing.Rectangle 0, 0, $small.Width, $small.Height), [System.Drawing.GraphicsUnit]::Pixel)
    } finally {
      $smallGraphics.Dispose()
      $small.Dispose()
    }
  } finally {
    $blur.Dispose()
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

  $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
  $graphics.Dispose()
  $bitmap.Dispose()
}

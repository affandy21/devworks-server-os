param(
  [Parameter(Mandatory = $true)]
  [string]$OutputPath,

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

try {
  $rect = New-Object System.Drawing.Rectangle 0, 0, $Width, $Height
  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect,
    [System.Drawing.Color]::FromArgb(5, 25, 43),
    [System.Drawing.Color]::FromArgb(8, 47, 75),
    0.0
  )
  $graphics.FillRectangle($bg, $rect)
  $bg.Dispose()

  $overlay = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect,
    [System.Drawing.Color]::FromArgb(42, 0, 132, 190),
    [System.Drawing.Color]::FromArgb(10, 2, 18, 35),
    30.0
  )
  $graphics.FillRectangle($overlay, $rect)
  $overlay.Dispose()

  $gridPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(90, 30, 145, 190)), 1
  $gridStep = [Math]::Max(40, [int]($Width / 16))
  for ($x = 0; $x -le $Width; $x += $gridStep) {
    $graphics.DrawLine($gridPen, $x, 0, $x, $Height)
  }
  for ($y = 0; $y -le $Height; $y += $gridStep) {
    $graphics.DrawLine($gridPen, 0, $y, $Width, $y)
  }
  $gridPen.Dispose()

  $finePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(28, 60, 190, 230)), 1
  $fineStep = [int]($gridStep / 2)
  for ($x = $fineStep; $x -le $Width; $x += $gridStep) {
    $graphics.DrawLine($finePen, $x, 0, $x, $Height)
  }
  for ($y = $fineStep; $y -le $Height; $y += $gridStep) {
    $graphics.DrawLine($finePen, 0, $y, $Width, $y)
  }
  $finePen.Dispose()

  $markPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(210, 111, 244, 240)), 2
  $markSize = [Math]::Round($Width * 0.112)
  $markX = [Math]::Round($Width * 0.08)
  $markY = [Math]::Round($Height * 0.10)
  $graphics.DrawEllipse($markPen, $markX, $markY, $markSize, $markSize)
  $markPen.Dispose()

  $textX = [Math]::Round($Width * 0.32)
  $titleY = [Math]::Round($Height * 0.132)
  $titleSize = [Math]::Max(28, [Math]::Round($Width * 0.047))
  $subSize = [Math]::Max(16, [Math]::Round($Width * 0.025))
  $lineSize = [Math]::Max(14, [Math]::Round($Width * 0.021))

  $fontTitle = New-Object System.Drawing.Font "Segoe UI", $titleSize, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
  $fontSub = New-Object System.Drawing.Font "Segoe UI", $subSize, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
  $fontLine = New-Object System.Drawing.Font "Segoe UI", $lineSize, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)

  $shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
  $whiteBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(245, 250, 255, 255))
  $cyanBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 101, 255, 247))

  $graphics.DrawString("Devworks Server OS", $fontTitle, $shadowBrush, $textX + 2, $titleY + 2)
  $graphics.DrawString("Devworks Server OS", $fontTitle, $whiteBrush, $textX, $titleY)
  $graphics.DrawString("v0.1.1 Server Hardening", $fontSub, $cyanBrush, $textX, $titleY + [Math]::Round($titleSize * 1.25))
  $graphics.DrawString("Installer permanen | GUI native | monitoring server", $fontLine, $whiteBrush, $textX, $titleY + [Math]::Round($titleSize * 2.05))

  $shadowBrush.Dispose()
  $whiteBrush.Dispose()
  $cyanBrush.Dispose()
  $fontTitle.Dispose()
  $fontSub.Dispose()
  $fontLine.Dispose()

  $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
  $graphics.Dispose()
  $bitmap.Dispose()
}

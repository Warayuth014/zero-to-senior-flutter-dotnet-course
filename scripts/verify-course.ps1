param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$manifest = Get-Content -LiteralPath (Join-Path $ProjectRoot 'course-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$coverage = [object[]](Get-Content -LiteralPath (Join-Path $ProjectRoot 'coverage-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
$sources = Get-Content -LiteralPath (Join-Path $ProjectRoot 'source-projects.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$lessons = @($manifest.parts | ForEach-Object { $_.topics })
$ids = @($lessons.id)
$authoredPartsPath = Join-Path $ProjectRoot 'content\authored-parts.json'
$authoredParts = if (Test-Path -LiteralPath $authoredPartsPath) {
  @(Get-Content -LiteralPath $authoredPartsPath -Raw -Encoding UTF8 | ConvertFrom-Json | Select-Object -ExpandProperty parts)
} else { @() }

$duplicateIds = $ids | Group-Object | Where-Object Count -gt 1
if ($duplicateIds) { throw "Duplicate lesson IDs: $($duplicateIds.Name -join ', ')" }

$missingLessons = @($lessons | Where-Object { -not (Test-Path -LiteralPath (Join-Path $ProjectRoot ($_.path -replace '/', '\'))) })
if ($missingLessons) { throw "Missing lesson files: $($missingLessons.id -join ', ')" }

$authoredLessons = @($lessons | Where-Object authored)
if ([int]$manifest.authoredCount -ne $authoredLessons.Count) {
  throw "Authored count mismatch: manifest=$($manifest.authoredCount), lessons=$($authoredLessons.Count)"
}

foreach ($partNumber in $authoredParts) {
  $partLessons = @($lessons | Where-Object { [int]$_.part -eq [int]$partNumber })
  if (-not $partLessons.Count) { throw "Authored part does not exist: $partNumber" }
  $scaffolds = @($partLessons | Where-Object { -not $_.authored })
  if ($scaffolds) { throw "Authored part $partNumber still has scaffolds: $($scaffolds.id -join ', ')" }
}

$contentFiles = @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'content') -Recurse -Filter '*.html' -File)
$expectedContent = @($authoredLessons | ForEach-Object { (Join-Path $ProjectRoot ($_.contentPath -replace '/', '\')).ToLowerInvariant() })
$orphanContent = @($contentFiles | Where-Object { $_.FullName.ToLowerInvariant() -notin $expectedContent })
if ($orphanContent) { throw "Content files do not map to lessons: $($orphanContent.FullName -join ', ')" }

$actualLessonCount = (Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'lessons') -Recurse -Filter '*.html' -File).Count
if ($actualLessonCount -ne $lessons.Count) { throw "Lesson count mismatch: manifest=$($lessons.Count), files=$actualLessonCount" }

$indexHtml = Get-Content -LiteralPath (Join-Path $ProjectRoot 'index.html') -Raw -Encoding UTF8
$rowCount = [regex]::Matches($indexHtml, '<a class="row"[^>]+data-id=').Count
if ($rowCount -ne $lessons.Count) { throw "Index row mismatch: rows=$rowCount, lessons=$($lessons.Count)" }

$searchJs = Get-Content -LiteralPath (Join-Path $ProjectRoot 'assets\search-index.js') -Raw -Encoding UTF8
$match = [regex]::Match($searchJs, 'Object\.freeze\((.*)\);', 'Singleline')
if (-not $match.Success) { throw 'Cannot parse assets/search-index.js' }
$searchObject = $match.Groups[1].Value | ConvertFrom-Json
$searchCount = @($searchObject.PSObject.Properties).Count
if ($searchCount -ne $lessons.Count) { throw "Search index mismatch: search=$searchCount, lessons=$($lessons.Count)" }

$missingCoverageLesson = @($coverage | Where-Object { $_.lessonId -notin $ids })
if ($missingCoverageLesson) { throw "Coverage points to missing lesson: $($missingCoverageLesson.lessonId -join ', ')" }

foreach ($source in $sources.projects) {
  $expected = @($coverage | Where-Object project -eq $source.id | ForEach-Object path)
  $current = @(
    Get-ChildItem -LiteralPath (Join-Path $source.root 'lib') -Recurse -Filter '*.dart' -File
    Get-ChildItem -LiteralPath (Join-Path $source.root 'test') -Recurse -Filter '*.dart' -File -ErrorAction SilentlyContinue
    foreach ($relative in @('pubspec.yaml','analysis_options.yaml','android/app/src/main/AndroidManifest.xml')) {
      $candidate = Join-Path $source.root ($relative -replace '/', '\')
      if (Test-Path -LiteralPath $candidate) { Get-Item -LiteralPath $candidate }
    }
  ) | Sort-Object FullName -Unique | ForEach-Object { $_.FullName.Substring($source.root.Length + 1).Replace('\','/') }
  $missing = @($current | Where-Object { $_ -notin $expected })
  $stale = @($expected | Where-Object { $_ -notin $current })
  if ($missing -or $stale) { throw "Coverage drift in $($source.id): missing=$($missing -join ','), stale=$($stale -join ',')" }
}

$courseJs = Get-Content -LiteralPath (Join-Path $ProjectRoot 'assets\course.js') -Raw -Encoding UTF8
if ($courseJs -notmatch "storagePrefix='zts_flutter_dotnet_'") { throw 'Wrong localStorage namespace' }

Write-Output "PASS: $($manifest.parts.Count) parts, $($lessons.Count) lessons, $($authoredLessons.Count) authored, $($coverage.Count) covered source/config files, full-text index complete"

param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$sources = Get-Content -LiteralPath (Join-Path $ProjectRoot 'source-projects.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$manifest = Get-Content -LiteralPath (Join-Path $ProjectRoot 'course-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$lessonIds = @($manifest.parts | ForEach-Object { $_.topics | ForEach-Object { $_.id } })
$coverage = New-Object System.Collections.Generic.List[object]
$snapshots = New-Object System.Collections.Generic.List[object]

function Map-WmsApp([string]$path) {
  switch -Regex ($path) {
    '^lib/main\.dart$' { return '16-02' }
    '^lib/theme/' { return '16-02' }
    '^lib/screens/home' { return '16-03' }
    '^lib/screens/login' { return '16-04' }
    '^lib/services/auth_session' { return '16-04' }
    '^lib/screens/settings' { return '16-05' }
    '^lib/services/(api_config|connection_probe)' { return '16-05' }
    '^lib/services/api_service' { return '16-06' }
    '^lib/services/sorting_signalr' { return '19-12' }
    '^lib/services/signalr' { return '18-08' }
    '^lib/services/api/receiving' { return '17-09' }
    '^lib/services/api/(unload|basket)' { return '17-13' }
    '^lib/services/api/putaway' { return '18-07' }
    '^lib/services/api/picking' { return '18-16' }
    '^lib/services/api/packing' { return '19-06' }
    '^lib/services/api/checkin' { return '19-09' }
    '^lib/services/api/sorting' { return '19-11' }
    '^lib/services/api/upload' { return '19-13' }
    '^lib/models/receiving' { return '17-09' }
    '^lib/models/(unload|basket)' { return '17-13' }
    '^lib/models/putaway' { return '18-07' }
    '^lib/models/picking' { return '18-10' }
    '^lib/models/packing' { return '19-06' }
    '^lib/models/checkin' { return '19-09' }
    '^lib/models/sorting' { return '19-11' }
    '^lib/models/' { return '16-08' }
    '^lib/screens/receiving/receiving_menu' { return '17-02' }
    '^lib/screens/receiving/scan_po/widgets/info' { return '17-04' }
    '^lib/screens/receiving/scan_po' { return '17-03' }
    '^lib/screens/receiving/scan_part/widgets/scan' { return '17-06' }
    '^lib/screens/receiving/scan_part' { return '17-05' }
    '^lib/screens/receiving/pending_pallet' { return '17-08' }
    '^lib/screens/receiving' { return '17-01' }
    '^lib/screens/unload/unload_menu' { return '17-10' }
    '^lib/screens/unload/load_to_basket' { return '17-11' }
    '^lib/screens/unload/unload_session' { return '17-12' }
    '^lib/screens/unload' { return '17-10' }
    '^lib/screens/putaway/putaway_main/widgets/station' { return '18-02' }
    '^lib/screens/putaway/putaway_prework/widgets/receive' { return '18-04' }
    '^lib/screens/putaway/putaway_prework/widgets/scan' { return '18-05' }
    '^lib/screens/putaway/putaway_prework/widgets/send' { return '18-04' }
    '^lib/screens/putaway/shared/widgets/destination' { return '18-05' }
    '^lib/screens/putaway/shared/widgets/pallet' { return '18-06' }
    '^lib/screens/putaway/putaway_prework' { return '18-04' }
    '^lib/screens/putaway' { return '18-01' }
    '^lib/screens/picking/orders_list' { return '18-09' }
    '^lib/screens/picking/order_detail' { return '18-10' }
    '^lib/screens/picking/picking_session' { return '18-11' }
    '^lib/screens/picking/pick_items/widgets/scan_source' { return '18-12' }
    '^lib/screens/picking/pick_items/widgets/scan_dest' { return '18-13' }
    '^lib/screens/picking/pick_items/widgets/after_pick' { return '18-14' }
    '^lib/screens/picking/pick_items/widgets/return_source' { return '18-15' }
    '^lib/screens/picking/pick_items' { return '18-14' }
    '^lib/screens/picking' { return '18-09' }
    '^lib/screens/packing' { return '19-01' }
    '^lib/screens/checkin' { return '19-07' }
    '^lib/screens/sorting' { return '19-10' }
    '^lib/screens/supervisor' { return '19-13' }
    '^lib/screens/test' { return '16-12' }
    '^lib/widgets/common_widgets' { return '16-09' }
    '^lib/widgets/part_thumbnail' { return '16-10' }
    '^test/' { return '16-12' }
    '^pubspec\.yaml$' { return '00-06' }
    '^analysis_options\.yaml$' { return '00-08' }
    '^android/.+AndroidManifest\.xml$' { return '15-03' }
    default { return '16-01' }
  }
}

function Map-Absolute([string]$path) {
  switch -Regex ($path) {
    '^lib/main\.dart$' { return '20-02' }
    '^lib/core/app_config' { return '20-03' }
    '^lib/core/api_client' { return '20-04' }
    '^lib/core/app_language' { return '20-08' }
    '^lib/core/app_theme' { return '20-09' }
    '^lib/core/connection_profile' { return '20-10' }
    '^lib/core/connection_controller' { return '20-11' }
    '^lib/core/connection_probe' { return '20-12' }
    '^lib/features/auth/auth_repository' { return '20-05' }
    '^lib/features/auth/auth_session' { return '20-06' }
    '^lib/features/auth/login_screen' { return '20-07' }
    '^lib/features/settings' { return '20-13' }
    '^lib/features/warehouse/warehouse_shell' { return '20-14' }
    '^lib/features/warehouse/ui/pda_colors' { return '20-09' }
    '^lib/features/warehouse/ui/user_chip' { return '20-15' }
    '^lib/widgets/pda_status' { return '20-15' }
    '^lib/features/warehouse/ui/pda_widgets' { return '22-16' }
    '^lib/features/warehouse/warehouse_store' { return '21-01' }
    '^lib/features/warehouse/workflow_definitions' { return '22-01' }
    '^lib/api/receiving' { return '21-04' }
    '^lib/api/inventory' { return '21-08' }
    '^lib/api/cycle_count' { return '21-11' }
    '^lib/api/tasks' { return '22-03' }
    '^lib/features/warehouse/models/inbound' { return '21-03' }
    '^lib/features/warehouse/models/inventory' { return '21-09' }
    '^lib/features/warehouse/models/cycle_count' { return '21-12' }
    '^lib/features/warehouse/models/(task|destination)' { return '22-02' }
    '^lib/features/warehouse/screens/receive' { return '21-05' }
    '^lib/features/warehouse/screens/inventory' { return '21-10' }
    '^lib/features/warehouse/screens/cycle_count' { return '21-14' }
    '^lib/features/warehouse/screens/task' { return '22-07' }
    '^lib/features/warehouse/screens/(ops|outbound)' { return '22-16' }
    '^lib/features/warehouse/screens/home' { return '20-14' }
    '^test/connection_profile' { return '20-10' }
    '^test/connection_settings' { return '20-13' }
    '^test/user_menu' { return '20-15' }
    '^test/(cycle_count|inventory)' { return '21-15' }
    '^test/(agv|conveyor|picking|withdraw|flow_navigation)' { return '22-17' }
    '^test/' { return '14-17' }
    '^pubspec\.yaml$' { return '00-06' }
    '^analysis_options\.yaml$' { return '00-08' }
    '^android/.+AndroidManifest\.xml$' { return '15-03' }
    default { return '20-01' }
  }
}

foreach ($source in $sources.projects) {
  if (-not (Test-Path -LiteralPath $source.root)) { throw "Missing source project: $($source.root)" }
  $files = @(
    Get-ChildItem -LiteralPath (Join-Path $source.root 'lib') -Recurse -Filter '*.dart' -File
    Get-ChildItem -LiteralPath (Join-Path $source.root 'test') -Recurse -Filter '*.dart' -File -ErrorAction SilentlyContinue
    foreach ($relative in @('pubspec.yaml','analysis_options.yaml','android/app/src/main/AndroidManifest.xml')) {
      $candidate = Join-Path $source.root ($relative -replace '/', '\')
      if (Test-Path -LiteralPath $candidate) { Get-Item -LiteralPath $candidate }
    }
  ) | Sort-Object FullName -Unique

  $lineCount = 0
  foreach ($file in $files) {
    $relative = $file.FullName.Substring($source.root.Length + 1).Replace('\','/')
    $lessonId = if ($source.id -eq 'wmsapp') { Map-WmsApp $relative } else { Map-Absolute $relative }
    if ($lessonId -notin $lessonIds) { throw "Coverage rule points to missing lesson $lessonId for $relative" }
    if ($file.Extension -eq '.dart') { $lineCount += (Get-Content -LiteralPath $file.FullName | Measure-Object -Line).Lines }
    $coverage.Add([pscustomobject]@{
      project = [string]$source.id
      path = $relative
      lessonId = $lessonId
      coverage = if ($relative -like 'lib/*') { 'deep' } else { 'reference' }
    })
  }

  $commit = (& git -C $source.root rev-parse HEAD 2>$null)
  $dirty = [bool]((& git -C $source.root status --porcelain 2>$null) -join '')
  $snapshots.Add([pscustomobject]@{
    id = [string]$source.id
    root = [string]$source.root
    commit = [string]$commit
    workingTreeDirty = $dirty
    trackedCourseFiles = $files.Count
    dartLines = $lineCount
  })
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'coverage-manifest.json'), ($coverage | ConvertTo-Json -Depth 5), $utf8)
$snapshot = [pscustomobject]@{ generatedAt=(Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK'); projects=$snapshots.ToArray() }
[System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'source-snapshot.json'), ($snapshot | ConvertTo-Json -Depth 5), $utf8)
Write-Output "Mapped $($coverage.Count) source/config files to lessons"

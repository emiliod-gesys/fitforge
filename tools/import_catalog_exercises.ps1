# Import exercises-dataset (excluding FitForge bundled matches) into Supabase.
#
# Requires service role key (never ship in the app).
#   $env:SUPABASE_URL = "https://xxx.supabase.co"
#   $env:SUPABASE_SERVICE_ROLE_KEY = "eyJ..."
#
# Usage:
#   pwsh tools/import_catalog_exercises.ps1 -Limit 20 -DryRun
#   pwsh tools/import_catalog_exercises.ps1

param(
  [string]$ZipPath = "$env:USERPROFILE\Downloads\exercises-dataset-main.zip",
  [string]$MatchCsv = "$PSScriptRoot\exercise_match_output\dataset\dataset_match_review.csv",
  [string]$DatasetJson = "$PSScriptRoot\third_party\exercises-dataset\data\exercises.json",
  [int]$Limit = 0,
  [switch]$DryRun,
  [switch]$SkipMedia
)

$ErrorActionPreference = 'Stop'

function Normalize-Text([string]$text) {
  if ([string]::IsNullOrWhiteSpace($text)) { return '' }
  $t = $text.ToLowerInvariant().Trim()
  $t = $t -replace '[áàä]', 'a' -replace '[éèë]', 'e' -replace '[íìï]', 'i'
  $t = $t -replace '[óòö]', 'o' -replace '[úùü]', 'u' -replace 'ñ', 'n'
  $t = $t -replace '[^a-z0-9]+', ' '
  return (($t.Trim()) -replace '\s+', ' ')
}

function Get-CategoryEs([string]$bodyPart, [string]$target) {
  switch ($bodyPart) {
    'chest' { return 'Pecho' }
    'back' { return 'Espalda' }
    'waist' { return 'Abdominales' }
    'shoulders' { return 'Hombros' }
    'lower legs' { return 'Pantorrillas' }
    'cardio' { return 'Cardio' }
    'upper legs' { return 'Piernas' }
    'upper arms' {
      if ($target -match 'biceps') { return 'Bíceps' }
      if ($target -match 'triceps') { return 'Tríceps' }
      return 'Brazos'
    }
    'lower arms' { return 'Antebrazos' }
    'neck' { return 'Cuello' }
    default { return 'Otros' }
  }
}

function Translate-Muscle([string]$muscle) {
  $m = $muscle.ToLowerInvariant().Trim()
  switch -Regex ($m) {
    'pectorals|pecs|chest' { return 'Pecho' }
    'biceps' { return 'Bíceps' }
    'triceps' { return 'Tríceps' }
    'lats|latissimus' { return 'Dorsales' }
    'delts|deltoids|shoulders' { return 'Hombros' }
    'quads|quadriceps' { return 'Cuádriceps' }
    'hamstrings' { return 'Isquios' }
    'glutes|gluteus' { return 'Glúteos' }
    'calves|gastrocnemius|soleus' { return 'Pantorrillas' }
    'abs|abdominals|core|obliques' { return 'Abdominales' }
    'forearms' { return 'Antebrazos' }
    'traps|trapezius' { return 'Trapecios' }
    'upper back|rhomboids' { return 'Espalda alta' }
    'lower back|spine|erector' { return 'Espalda baja' }
    'adductors|abductors' { return 'Aductores' }
    'cardiovascular' { return 'Cardio' }
    default { return ($muscle.Substring(0,1).ToUpper() + $muscle.Substring(1)) }
  }
}

function Translate-Equipment([string]$equipment) {
  switch ($equipment.ToLowerInvariant().Trim()) {
    'body weight' { return 'Peso corporal' }
    'dumbbell' { return 'Mancuernas' }
    'barbell' { return 'Barra' }
    'cable' { return 'Polea' }
    'leverage machine' { return 'Máquina' }
    'smith machine' { return 'Smith' }
    'band' { return 'Banda' }
    'kettlebell' { return 'Kettlebell' }
    'ez barbell' { return 'Barra EZ' }
    'stability ball' { return 'Balón' }
    'assisted' { return 'Asistido' }
    default { return ($equipment.Substring(0,1).ToUpper() + $equipment.Substring(1)) }
  }
}

function Infer-LoadMode([string]$equipment, [string]$name) {
  $n = $name.ToLowerInvariant()
  switch ($equipment.ToLowerInvariant().Trim()) {
    'body weight' {
      if ($n -match 'assisted') { return 'assisted_bodyweight' }
      return 'bodyweight'
    }
    'dumbbell' {
      if ($n -match 'single arm|one arm|alternating') { return 'single_load' }
      return 'dual_load'
    }
    'barbell' { return 'single_load' }
    'cable' { return 'machine_stack' }
    'leverage machine' { return 'machine_stack' }
    'smith machine' { return 'machine_stack' }
    'band' { return 'single_load' }
    'kettlebell' { return 'single_load' }
    default { return 'single_load' }
  }
}

function Infer-Flags([string]$name) {
  $n = $name.ToLowerInvariant()
  return @{
    per_arm_weight = [bool]($n -match 'single arm|one arm|alternating|each arm|per arm')
    unilateral = [bool]($n -match 'single arm|one arm|single leg|one leg|pistol|unilateral')
  }
}

function Build-SearchText($item) {
  $parts = @(
    $item.name
    $item.target
    $item.muscle_group
    $item.equipment
    $item.body_part
  )
  if ($item.secondary_muscles) { $parts += $item.secondary_muscles }
  if ($item.instructions.es) { $parts += ($item.instructions.es.Substring(0, [Math]::Min(180, $item.instructions.es.Length))) }
  return (Normalize-Text ($parts -join ' '))
}

function Invoke-SupabaseJsonPost([string]$Uri, [hashtable]$Headers, [string]$JsonBody) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($JsonBody)
  try {
    Invoke-WebRequest -Method Post -Uri $Uri -Headers $Headers -Body $bytes -UseBasicParsing | Out-Null
  } catch {
    $detail = $_.Exception.Message
    if ($_.Exception.Response) {
      $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
      $body = $reader.ReadToEnd()
      if ($body) { $detail = "$detail | $body" }
    }
    throw $detail
  }
}

function Invoke-SupabaseBinaryPost([string]$Uri, [hashtable]$Headers, [byte[]]$Body, [string]$ContentType) {
  try {
    Invoke-WebRequest -Method Post -Uri $Uri -Headers ($Headers + @{ 'Content-Type' = $ContentType }) -Body $Body -UseBasicParsing | Out-Null
  } catch {
    $detail = $_.Exception.Message
    if ($_.Exception.Response) {
      $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
      $body = $reader.ReadToEnd()
      if ($body) { $detail = "$detail | $body" }
    }
    throw $detail
  }
}

function ConvertTo-JsonDeep($obj) {
  Add-Type -AssemblyName System.Web.Extensions
  $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
  $ser.MaxJsonLength = 67108864
  return $ser.Serialize($obj)
}

function To-StringArray($value) {
  if ($null -eq $value) { return @() }
  if ($value -is [System.Array]) {
    return @($value | ForEach-Object { "$_" })
  }
  return @("$value")
}

function To-StringList($value) {
  $list = New-Object 'System.Collections.Generic.List[string]'
  foreach ($v in (To-StringArray $value)) {
    [void]$list.Add($v)
  }
  return $list
}

$supabaseUrl = $env:SUPABASE_URL
$serviceKey = $env:SUPABASE_SERVICE_ROLE_KEY
if (-not $DryRun -and (-not $supabaseUrl -or -not $serviceKey)) {
  throw 'Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables.'
}

if (-not (Test-Path $DatasetJson)) {
  throw "Dataset JSON not found: $DatasetJson"
}
if (-not (Test-Path $ZipPath)) {
  throw "ZIP not found: $ZipPath"
}

$excludeIds = @{}
if (Test-Path $MatchCsv) {
  Import-Csv $MatchCsv | Where-Object { $_.match_confidence -in @('high', 'medium') -and $_.dataset_id } | ForEach-Object {
    $excludeIds[$_.dataset_id] = $true
  }
}

Write-Host "Excluded dataset IDs (FitForge overlap): $($excludeIds.Count)" -ForegroundColor Cyan

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)

$dataset = Get-Content $DatasetJson -Raw -Encoding UTF8 | ConvertFrom-Json
$toImport = @($dataset | Where-Object { -not $excludeIds.ContainsKey($_.id) })
if ($Limit -gt 0) { $toImport = $toImport | Select-Object -First $Limit }

Write-Host "Importing $($toImport.Count) exercises$(if ($DryRun) { ' (DRY RUN)' })" -ForegroundColor Green

$headers = @{
  apikey = $serviceKey
  Authorization = "Bearer $serviceKey"
  'Content-Type' = 'application/json'
}

$inserted = 0
$failed = 0

foreach ($item in $toImport) {
  $datasetId = $item.id
  $cloudId = "ext_$datasetId"
  $flags = Infer-Flags $item.name
  $loadMode = Infer-LoadMode $item.equipment $item.name
  $loggingType = if ($item.body_part -eq 'cardio') { 'cardio' } else { 'strength' }
  $categoryEs = Get-CategoryEs $item.body_part $item.target
  $muscles = @()
  if ($item.target) { $muscles += (Translate-Muscle $item.target) }
  foreach ($sm in @($item.secondary_muscles)) {
    $translated = Translate-Muscle $sm
    if ($muscles -notcontains $translated) { $muscles += $translated }
  }
  $descEs = ($item.instruction_steps.es -join "`n`n").Trim()
  $descEn = ($item.instruction_steps.en -join "`n`n").Trim()
  $equipmentEs = Translate-Equipment $item.equipment

  $imagePath = $item.image -replace '\\', '/'
  $gifPath = $item.gif_url -replace '\\', '/'
  $imageEntry = if ($imagePath) { $zip.GetEntry("exercises-dataset-main/$imagePath") } else { $null }
  $gifEntry = if ($gifPath) { $zip.GetEntry("exercises-dataset-main/$gifPath") } else { $null }

  $publicBase = "$supabaseUrl/storage/v1/object/public/exercise-media"
  $imageUrl = "$publicBase/$datasetId/thumb.jpg"
  $gifUrl = "$publicBase/$datasetId/anim.gif"

  if ($DryRun) {
    Write-Host "  [dry] $cloudId $($item.name)"
    continue
  }

  try {
    if (-not $SkipMedia) {
      $uploadHeaders = @{ apikey = $serviceKey; Authorization = "Bearer $serviceKey"; 'x-upsert' = 'true' }
      if ($imageEntry) {
        $ms = New-Object System.IO.MemoryStream
        $imageEntry.Open().CopyTo($ms)
        $bytes = $ms.ToArray()
        $ms.Dispose()
        Invoke-SupabaseBinaryPost -Uri "$supabaseUrl/storage/v1/object/exercise-media/$datasetId/thumb.jpg" `
          -Headers $uploadHeaders -Body $bytes -ContentType 'image/jpeg'
      }
      if ($gifEntry) {
        $ms = New-Object System.IO.MemoryStream
        $gifEntry.Open().CopyTo($ms)
        $bytes = $ms.ToArray()
        $ms.Dispose()
        Invoke-SupabaseBinaryPost -Uri "$supabaseUrl/storage/v1/object/exercise-media/$datasetId/anim.gif" `
          -Headers $uploadHeaders -Body $bytes -ContentType 'image/gif'
      }
    }

    $row = [ordered]@{
      id = $cloudId
      dataset_id = $datasetId
      media_id = $item.media_id
      name_en = $item.name
      name_es = $item.name
      category = $categoryEs
      body_part = $item.body_part
      equipment = $equipmentEs
      target_muscle = $item.target
      muscle_group = $item.muscle_group
      secondary_muscles = (To-StringList $item.secondary_muscles)
      muscles = (To-StringList $muscles)
      description_en = $descEn
      description_es = $descEs
      instruction_steps_en = (To-StringList $item.instruction_steps.en)
      instruction_steps_es = (To-StringList $item.instruction_steps.es)
      logging_type = $loggingType
      load_mode = $loadMode
      per_arm_weight = [bool]$flags.per_arm_weight
      unilateral = [bool]$flags.unilateral
      weight_optional = [bool]($loadMode -in @('bodyweight', 'assisted_bodyweight') -or $loggingType -eq 'cardio')
      image_url = $imageUrl
      gif_url = $gifUrl
      attribution = $item.attribution
      search_text = (Build-SearchText $item)
    }

    $jsonBody = ConvertTo-JsonDeep $row
    Invoke-SupabaseJsonPost -Uri "$supabaseUrl/rest/v1/catalog_exercises?on_conflict=id" `
      -Headers ($headers + @{ Prefer = 'resolution=merge-duplicates' }) `
      -JsonBody $jsonBody

    $inserted++
    if ($inserted % 25 -eq 0) {
      Write-Host "  ... $inserted uploaded" -ForegroundColor DarkGray
    }
  } catch {
    $failed++
    Write-Warning "Failed $cloudId $($item.name): $($_.Exception.Message)"
  }
}

$zip.Dispose()

Write-Host "`nDone. Inserted/updated: $inserted | Failed: $failed" -ForegroundColor Yellow

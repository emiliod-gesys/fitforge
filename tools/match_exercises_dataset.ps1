# Match FitForge bundled catalog against local exercises-dataset JSON.
# Usage: pwsh tools/match_exercises_dataset.ps1

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$CatalogPath = Join-Path $Root 'assets/data/exercise_catalog.json'
$DatasetPath = Join-Path $Root 'tools/third_party/exercises-dataset/data/exercises.json'
$OutDir = Join-Path $Root 'tools/exercise_match_output/dataset'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Normalize-Text([string]$text) {
    if ([string]::IsNullOrWhiteSpace($text)) { return '' }
    $t = $text.ToLowerInvariant().Trim()
    $t = $t -replace '[áàä]', 'a' -replace '[éèë]', 'e' -replace '[íìï]', 'i'
    $t = $t -replace '[óòö]', 'o' -replace '[úùü]', 'u' -replace 'ñ', 'n'
    $t = $t -replace '[^a-z0-9]+', ' '
    return (($t.Trim()) -replace '\s+', ' ')
}

function Token-Set([string]$text) {
    $norm = Normalize-Text $text
    if ($norm -eq '') { return @{} }
    $set = @{}
    foreach ($tok in ($norm -split ' ')) {
        if ($tok.Length -ge 2) { $set[$tok] = $true }
    }
    return $set
}

function Jaccard-Score([string]$a, [string]$b) {
    $sa = Token-Set $a
    $sb = Token-Set $b
    if ($sa.Count -eq 0 -or $sb.Count -eq 0) { return 0.0 }
    $inter = 0
    foreach ($k in $sa.Keys) {
        if ($sb.ContainsKey($k)) { $inter++ }
    }
    $union = $sa.Count + $sb.Count - $inter
    if ($union -eq 0) { return 0.0 }
    return [double]$inter / [double]$union
}

function Confidence-Label([double]$score) {
    if ($score -ge 0.72) { return 'high' }
    if ($score -ge 0.55) { return 'medium' }
    if ($score -ge 0.40) { return 'low' }
    return 'none'
}

Write-Host "Loading FitForge catalog..." -ForegroundColor Cyan
$catalog = Get-Content $CatalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
$ffItems = @($catalog.exercises | ForEach-Object {
    [pscustomobject]@{
        ff_id = $_.id
        name_en = $_.names.en
        name_es = $_.names.es
        equipment_en = $_.equipment.en
        primary_muscle_en = $_.primaryMuscle.en
        has_description_es = -not [string]::IsNullOrWhiteSpace($_.descriptions.es)
        exercisedb_id = $_.exercisedbId
    }
})

Write-Host "Loading exercises-dataset ($DatasetPath)..." -ForegroundColor Cyan
$dataset = Get-Content $DatasetPath -Raw -Encoding UTF8 | ConvertFrom-Json
$dsItems = @($dataset | ForEach-Object {
    $mediaId = $null
    if ($_.gif_url -match '([A-Za-z0-9]{6,12})\.gif$') { $mediaId = $Matches[1] }
    [pscustomobject]@{
        id = $_.id
        name = $_.name
        equipment = $_.equipment
        body_part = $_.body_part
        target = $_.target
        media_id = $mediaId
        gif_url = $_.gif_url
        image = $_.image
        has_instructions_es = ($_.instruction_steps.es -ne $null -and $_.instruction_steps.es.Count -gt 0)
    }
})

Write-Host "FitForge: $($ffItems.Count) | Dataset: $($dsItems.Count)" -ForegroundColor Green

$byMediaId = @{}
foreach ($d in $dsItems) {
    if ($d.media_id) { $byMediaId[$d.media_id] = $d }
}

$matches = @()
$unmatched = @()

foreach ($ff in $ffItems) {
    $best = $null
    $bestScore = 0.0

    if ($ff.exercisedb_id -and $byMediaId.ContainsKey($ff.exercisedb_id)) {
        $candidate = $byMediaId[$ff.exercisedb_id]
        $best = $candidate
        $bestScore = 0.95
    } else {
        foreach ($d in $dsItems) {
            $score = [Math]::Max(
                (Jaccard-Score $ff.name_en $d.name),
                (Jaccard-Score $ff.name_es $d.name)
            )
            if ($score -gt $bestScore) {
                $bestScore = $score
                $best = $d
            }
        }
    }

    $label = Confidence-Label $bestScore
    $entry = [pscustomobject]@{
        ff_id = $ff.ff_id
        name_en = $ff.name_en
        name_es = $ff.name_es
        equipment = $ff.equipment_en
        match_confidence = $label
        match_score = [Math]::Round($bestScore, 4)
        dataset_id = $best.id
        dataset_name = $best.name
        media_id = $best.media_id
        has_instructions_es = $best.has_instructions_es
        can_enrich_description = (-not $ff.has_description_es) -and $best.has_instructions_es
    }

    if ($label -eq 'none') { $unmatched += $entry } else { $matches += $entry }
}

$summary = [ordered]@{
    generated_at = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
    fitforge_total = $ffItems.Count
    dataset_total = $dsItems.Count
    matched_high = @($matches | Where-Object match_confidence -eq 'high').Count
    matched_medium = @($matches | Where-Object match_confidence -eq 'medium').Count
    matched_low = @($matches | Where-Object match_confidence -eq 'low').Count
    unmatched = $unmatched.Count
    enrichable_descriptions_es = @($matches | Where-Object can_enrich_description).Count
    dataset_only_estimate = $dsItems.Count - @($matches | Where-Object match_confidence -in @('high','medium')).Count
}

$summary | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutDir 'dataset_match_summary.json') -Encoding UTF8
@($matches + $unmatched) | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutDir 'dataset_match_results.json') -Encoding UTF8

$csvPath = Join-Path $OutDir 'dataset_match_review.csv'
@($matches + $unmatched) |
    Sort-Object match_score -Descending |
    Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "`n=== DATASET MATCH SUMMARY ===" -ForegroundColor Yellow
$summary.GetEnumerator() | ForEach-Object { Write-Host ("  {0}: {1}" -f $_.Key, $_.Value) }
Write-Host "`nOutput: $OutDir" -ForegroundColor Cyan

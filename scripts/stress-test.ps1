# =============================================================================
# Stress Test Script for Todo API (PowerShell Version)
# =============================================================================
# Usage:
#   .\scripts\stress-test.ps1 [-Url <string>] [-Duration <int>] [-Concurrent <int>] [-Rate <int>] [-TestType <string>]
#
# Examples:
#   .\scripts\stress-test.ps1
#   .\scripts\stress-test.ps1 -Duration 30 -Rate 100
#   .\scripts\stress-test.ps1 -Url "http://192.168.1.100:3000" -TestType "all"
# =============================================================================

param(
    [string]$Url = "http://localhost:3000",
    [int]$Duration = 60,
    [int]$Concurrent = 10,
    [int]$Rate = 50,
    [ValidateSet("all", "read", "write", "mixed")]
    [string]$TestType = "mixed"
)

# Colors
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Blue = "Cyan"

function Write-Banner {
    Write-Host "============================================" -ForegroundColor $Blue
    Write-Host "   [STRESS TEST] Todo API Stress Test" -ForegroundColor $Blue
    Write-Host "============================================" -ForegroundColor $Blue
    Write-Host "Configuration:" -ForegroundColor $Yellow
    Write-Host "  Base URL:    $Url" -ForegroundColor $Green
    Write-Host "  Duration:    ${Duration}s" -ForegroundColor $Green
    Write-Host "  Concurrent:  $Concurrent" -ForegroundColor $Green
    Write-Host "  Rate:        $Rate req/s" -ForegroundColor $Green
    Write-Host "  Test Type:   $TestType" -ForegroundColor $Green
    Write-Host "============================================" -ForegroundColor $Blue
    Write-Host ""
}

function Test-ApiHealth {
    Write-Host "[CHECK] Checking API health..." -ForegroundColor $Yellow
    try {
        $response = Invoke-RestMethod -Uri "$Url/health" -Method Get -TimeoutSec 5
        Write-Host "[OK] API is healthy!" -ForegroundColor $Green
        return $true
    }
    catch {
        Write-Host "[FAIL] API is not reachable at $Url" -ForegroundColor $Red
        return $false
    }
}

function New-TestTodo {
    Write-Host "[SETUP] Creating test todo..." -ForegroundColor $Yellow
    try {
        $body = @{
            title = "Stress Test Todo"
            description = "Created for stress testing"
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$Url/todos" -Method Post -Body $body -ContentType "application/json"
        Write-Host "[OK] Created test todo with ID: $($response.id)" -ForegroundColor $Green
        return $response.id
    }
    catch {
        Write-Host "[FAIL] Failed to create test todo: $_" -ForegroundColor $Red
        return $null
    }
}

function Invoke-StressTest {
    param(
        [string]$Endpoint,
        [string]$Method,
        [string]$Body,
        [string]$Description,
        [int]$TotalRequests,
        [int]$ConcurrentLimit
    )
    
    Write-Host "[TEST] Testing: $Description" -ForegroundColor $Yellow
    Write-Host "   Endpoint: $Method $Endpoint"
    Write-Host "   Total Requests: $TotalRequests"
    Write-Host "   Concurrent: $ConcurrentLimit"
    
    $startTime = Get-Date
    $success = 0
    $failed = 0
    $jobs = @()
    
    # Create script block for each request
    $scriptBlock = {
        param($url, $method, $body)
        try {
            if ($method -eq "GET") {
                $null = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 30 -UseBasicParsing
            }
            elseif ($method -eq "POST") {
                $null = Invoke-WebRequest -Uri $url -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30 -UseBasicParsing
            }
            elseif ($method -eq "PATCH") {
                $null = Invoke-WebRequest -Uri $url -Method Patch -Body $body -ContentType "application/json" -TimeoutSec 30 -UseBasicParsing
            }
            return $true
        }
        catch {
            return $false
        }
    }
    
    # Run requests in batches
    $batchSize = [Math]::Min($ConcurrentLimit, $TotalRequests)
    $batches = [Math]::Ceiling($TotalRequests / $batchSize)
    
    for ($batch = 0; $batch -lt $batches; $batch++) {
        $currentBatchSize = [Math]::Min($batchSize, $TotalRequests - ($batch * $batchSize))
        $jobs = @()
        
        for ($i = 0; $i -lt $currentBatchSize; $i++) {
            $fullUrl = "$Url$Endpoint"
            $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $fullUrl, $Method, $Body
            $jobs += $job
        }
        
        # Wait for batch to complete
        $results = $jobs | Wait-Job | Receive-Job
        $jobs | Remove-Job
        
        foreach ($result in $results) {
            if ($result) { $success++ } else { $failed++ }
        }
        
        # Progress indicator
        $progress = [Math]::Round((($batch + 1) / $batches) * 100)
        Write-Progress -Activity "Stress Testing $Description" -Status "$progress% Complete" -PercentComplete $progress
    }
    
    Write-Progress -Activity "Stress Testing $Description" -Completed
    
    $endTime = Get-Date
    $elapsed = ($endTime - $startTime).TotalSeconds
    $rps = [Math]::Round($TotalRequests / $elapsed, 2)
    
    $resultColor = if ($failed -eq 0) { $Green } else { $Yellow }
    Write-Host "   [OK] Success: $success | [FAIL] Failed: $failed" -ForegroundColor $resultColor
    Write-Host "   Time: ${elapsed}s | Rate: $rps req/s"
    Write-Host ""
    
    return @{
        Success = $success
        Failed = $failed
        Duration = $elapsed
        RPS = $rps
    }
}

function Remove-TestTodo {
    param([int]$TodoId)
    
    Write-Host "[CLEANUP] Cleaning up test data..." -ForegroundColor $Yellow
    try {
        Invoke-RestMethod -Uri "$Url/todos/$TodoId" -Method Delete
        Write-Host "[OK] Cleanup complete!" -ForegroundColor $Green
    }
    catch {
        Write-Host "[WARN] Cleanup warning: $_" -ForegroundColor $Yellow
    }
}

# Main execution
Write-Banner

if (-not (Test-ApiHealth)) {
    exit 1
}
Write-Host ""

$testTodoId = New-TestTodo
if (-not $testTodoId) {
    exit 1
}
Write-Host ""

# Calculate total requests
$TotalRequests = $Duration * $Rate

Write-Host "============================================" -ForegroundColor $Blue
Write-Host "   [START] Starting Stress Tests" -ForegroundColor $Blue
Write-Host "============================================" -ForegroundColor $Blue
Write-Host ""

$results = @()

switch ($TestType) {
    "read" {
        $results += Invoke-StressTest -Endpoint "/health" -Method "GET" -Description "Health Check" -TotalRequests ([Math]::Floor($TotalRequests / 2)) -ConcurrentLimit $Concurrent
        $results += Invoke-StressTest -Endpoint "/todos" -Method "GET" -Description "Get All Todos" -TotalRequests ([Math]::Floor($TotalRequests / 2)) -ConcurrentLimit $Concurrent
    }
    "write" {
        $body = '{"title":"Stress Test","description":"Created during stress test"}'
        $results += Invoke-StressTest -Endpoint "/todos" -Method "POST" -Body $body -Description "Create Todo" -TotalRequests $TotalRequests -ConcurrentLimit $Concurrent
    }
    "mixed" {
        $body = '{"title":"Stress Test","description":"Created during stress test"}'
        $results += Invoke-StressTest -Endpoint "/health" -Method "GET" -Description "Health Check" -TotalRequests ([Math]::Floor($TotalRequests / 4)) -ConcurrentLimit $Concurrent
        $results += Invoke-StressTest -Endpoint "/todos" -Method "GET" -Description "Get All Todos" -TotalRequests ([Math]::Floor($TotalRequests / 4)) -ConcurrentLimit $Concurrent
        $results += Invoke-StressTest -Endpoint "/todos/$testTodoId" -Method "GET" -Description "Get Single Todo" -TotalRequests ([Math]::Floor($TotalRequests / 4)) -ConcurrentLimit $Concurrent
        $results += Invoke-StressTest -Endpoint "/todos" -Method "POST" -Body $body -Description "Create Todo" -TotalRequests ([Math]::Floor($TotalRequests / 4)) -ConcurrentLimit $Concurrent
    }
    "all" {
        $body = '{"title":"Stress Test","description":"Created during stress test"}'
        $updateBody = '{"title":"Updated Stress Test"}'
        
        Write-Host "[PHASE 1] Health Checks" -ForegroundColor $Yellow
        $results += Invoke-StressTest -Endpoint "/health" -Method "GET" -Description "Health Check" -TotalRequests ([Math]::Floor($TotalRequests / 5)) -ConcurrentLimit $Concurrent
        
        Write-Host "[PHASE 2] Read Operations" -ForegroundColor $Yellow
        $results += Invoke-StressTest -Endpoint "/todos" -Method "GET" -Description "Get All Todos" -TotalRequests ([Math]::Floor($TotalRequests / 5)) -ConcurrentLimit $Concurrent
        $results += Invoke-StressTest -Endpoint "/todos/$testTodoId" -Method "GET" -Description "Get Single Todo" -TotalRequests ([Math]::Floor($TotalRequests / 5)) -ConcurrentLimit $Concurrent
        
        Write-Host "[PHASE 3] Write Operations" -ForegroundColor $Yellow
        $results += Invoke-StressTest -Endpoint "/todos" -Method "POST" -Body $body -Description "Create Todo" -TotalRequests ([Math]::Floor($TotalRequests / 5)) -ConcurrentLimit $Concurrent
        $results += Invoke-StressTest -Endpoint "/todos/$testTodoId" -Method "PATCH" -Body $updateBody -Description "Update Todo" -TotalRequests ([Math]::Floor($TotalRequests / 5)) -ConcurrentLimit $Concurrent
    }
}

# Cleanup
Write-Host ""
Remove-TestTodo -TodoId $testTodoId
Write-Host ""

# Summary
$totalSuccess = ($results | Measure-Object -Property Success -Sum).Sum
$totalFailed = ($results | Measure-Object -Property Failed -Sum).Sum
$totalDuration = ($results | Measure-Object -Property Duration -Sum).Sum
$avgRps = [Math]::Round(($results | Measure-Object -Property RPS -Average).Average, 2)

Write-Host "============================================" -ForegroundColor $Blue
Write-Host "   [DONE] Stress Test Complete!" -ForegroundColor $Blue
Write-Host "============================================" -ForegroundColor $Blue
Write-Host ""
Write-Host "[SUMMARY]" -ForegroundColor $Yellow
Write-Host "   Total Requests: $($totalSuccess + $totalFailed)"
Write-Host "   Success: $totalSuccess" -ForegroundColor $Green
$failColor = if ($totalFailed -eq 0) { $Green } else { $Red }
Write-Host "   Failed: $totalFailed" -ForegroundColor $failColor
Write-Host "   Average RPS: $avgRps"
Write-Host ""
Write-Host "[TIPS]" -ForegroundColor $Yellow
Write-Host "  - Check Grafana dashboard to see the metrics"
Write-Host "  - Monitor error rate, latency, and throughput"
Write-Host "  - Prometheus URL: http://localhost:9090"
Write-Host "  - Grafana URL: http://localhost:3001"
Write-Host ""

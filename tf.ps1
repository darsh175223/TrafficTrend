# =============================================================================
# TrafficTrend - Terraform Environment Loader
# =============================================================================
# This script loads variables from a .env file into the shell environment
# as TF_VAR_ variables so Terraform can read them.
# =============================================================================

function Load-Env {
    if (Test-Path ".env") {
        Write-Host "Loading .env file..." -ForegroundColor Cyan
        Get-Content .env | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
            $key, $value = $_.Split('=', 2)
            $key = $key.Trim()
            $value = $value.Trim()
            
            # Remove quotes if present
            $value = $value -replace '^["'']|["'']$'
            
            [System.Environment]::SetEnvironmentVariable($key, $value, "Process")
            Write-Host "Set $key" -ForegroundColor Gray
        }
    } else {
        Write-Warning ".env file not found! Use .env.example as a template."
    }
}

# Load the environment
Load-Env

# Run terraform with passed arguments
if ($args.Count -gt 0) {
    cd terraform
    terraform @args
    cd ..
} else {
    Write-Host "`nEnvironment loaded! You can now run terraform commands." -ForegroundColor Green
    Write-Host "Example: .\tf.ps1 plan"
}

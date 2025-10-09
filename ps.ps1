# commands.ps1

function Build {
    Write-Host "Building project..."
    # Example: Compile C# project
    mix compile
    mix escript.build
}

function Test {
    Write-Host "Running tests..."
    # Example: Run unit tests
    mix test
}

function Run {
    Write-Host "Running Iex Iterative..."
    iex.bat -S mix  
}

function Bash {
    Write-Host "Running bash..."
    Build
    docker compose run --rm ledger sh
}

function Compose-Up {
    docker-compose up -d --remove-orphans $args[1]
}

# Allow calling specific functions from the command line
if ($args.Count -gt 0) {
    Invoke-Expression "$($args[0])"
} else {
    All # Default target if no arguments are provided
}
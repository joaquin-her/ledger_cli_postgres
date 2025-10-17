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

function cover {
    Write-Host "Running coverage..."
    mix test --cover
}

function Lines {
    param(
        [Parameter(Mandatory=$true)]
        [int]$CommitCount,

        [string]$AuthorEmail = (git config user.email)
    )

    # 1. Inicializa las variables para acumular los totales
    $totalAdded = 0
    $totalDeleted = 0

    # 2. Ejecuta git log y procesa la salida línea por línea
    git log -n $CommitCount --author="$AuthorEmail" --pretty=tformat: --numstat | ForEach-Object { 
        # Divide la línea por el tabulador
        $parts = $_ -split '\t'

        # Asegúrate de que la línea tenga 3 partes (añadidas, eliminadas, archivo)
        if ($parts.Count -ge 3) {
            # Convierte y suma las líneas añadidas y eliminadas
            $totalAdded += [int]$parts[0]
            $totalDeleted += [int]$parts[1]
        }
    }

    # 3. Imprime el resultado final después de procesar todos los commits
    Write-Host "--- Resumen de las ultimos 24 horas de codigo ---"
    Write-Host "Lineas aniadidas: $totalAdded"
    Write-Host "Lineas eliminadas: $totalDeleted"
    Write-Host "Total neto: $($totalAdded - $totalDeleted)"
}

# Allow calling specific functions from the command line
if ($args.Count -gt 0) {
    Invoke-Expression "$($args[0])"
} else {
    All # Default target if no arguments are provided
}
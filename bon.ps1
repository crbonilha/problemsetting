<#
problems/
    $problem/
        io/
        solutions/
        checkers/
        generators/
#>

param (
    $problems,
    [switch]$checkIo = $false,
    [switch]$checkSolutions = $false
)

function Invoke-Io-Validation {
    param ($problem)

    if (!(Test-Path ./problems/$problem/checkers -PathType Container)) {
        return
    }

    $checkers = Get-ChildItem -Path ./problems/$problem/checkers/*.cpp `
        -Name
    foreach ($checker in $checkers) {
        Write-Host "Working on checker $checker."

        g++ ./problems/$problem/checkers/$checker `
            -o ./problems/$problem/checkers/$checker.exe

        if (!(Test-Path ./problems/$problem/checkers/temp.txt)) {
            New-Item -Path ./problems/$problem/checkers/ `
                -Name "temp.txt" `
                -ItemType "file" `
                -Value ""
        }
        Clear-Content ./problems/$problem/checkers/temp.txt

        $tc_sets = Get-ChildItem -Path ./problems/$problem/io/ `
            -Name `
            -Attributes D
        foreach ($tc_set in $tc_sets) {
            Write-Host "Checking the TC set #$tc_set"

            $log_map = @{}

            $tcs = Get-ChildItem -Path ./problems/$problem/io/$tc_set/*.in `
                -Name
            foreach ($tc in $tcs) {
                Get-Content ./problems/$problem/io/$tc_set/$tc | `
                    & ./problems/$problem/checkers/$checker.exe `
                    > ./problems/$problem/checkers/temp.txt

                $checker_log = Get-Content ./problems/$problem/checkers/temp.txt
                foreach ($log_line in $checker_log) {
                    $log_line = $log_line.ToLower()
                    if ($log_line.Contains("wrong")) {
                        Write-Host "$tc : $log_line"
                    }

                    $statements = $log_line.Split(",")
                    foreach ($statement in $statements) {
                        $statement = $statement.Trim()

                        if ("" -eq $statement) {
                            continue
                        }

                        if ($null -eq $log_map[$statement]) {
                            $log_map[$statement] = 0
                        }
                        $log_map[$statement]++
                    }
                }
            }

            foreach ($key in $log_map.keys) {
                $value = $log_map[$key]
                Write-Host "$key : $value"
            }
        }
    }
}

function Invoke-Solution-Validation {
    param ($problem)

    if (!(Test-Path ./problems/$problem/solutions -PathType Container)) {
        return
    }

    $solutions = Get-ChildItem -Path ./problems/$problem/solutions/*.cpp `
        -Name
    foreach ($solution in $solutions) {
        Write-Host "Working on solution $solution."

        g++ ./problems/$problem/solutions/$solution `
            -o ./problems/$problem/solutions/$solution.exe

        if (!(Test-Path ./problems/$problem/solutions/temp.txt)) {
            New-Item -Path ./problems/$problem/io/ `
                -Name "temp.txt" `
                -ItemType "file" `
                -Value "."
        }

        $tc_sets = Get-ChildItem -Path ./problems/$problem/io/ `
            -Name `
            -Attributes D
        foreach ($tc_set in $tc_sets) {
            Write-Host "Checking the TC set #$tc_set : " -NoNewline

            $tested_count = 0
            $accepted_count = 0

            $tcs = Get-ChildItem -Path ./problems/$problem/io/$tc_set/*.in `
                -Name
            foreach ($tc in $tcs) {
                Get-Content ./problems/$problem/io/$tc_set/$tc | `
                    & ./problems/$problem/solutions/$solution.exe `
                    > ./problems/$problem/solutions/temp.txt

                $tested_count++

                if ($null -eq (Get-Content -Path ./problems/$problem/solutions/temp.txt)) {
                    continue;
                }

                $tc_sol = $tc.Split(".")[0]

                # compare the objects
                $diff = Compare-Object `
                    -ReferenceObject (Get-Content -Path ./problems/$problem/io/$tc_set/$tc_sol.out) `
                    -DifferenceObject (Get-Content -Path ./problems/$problem/solutions/temp.txt)

                if ($null -eq $diff) {
                    $accepted_count++
                }
            }

            $foreground_color = "Red"
            if ($accepted_count -eq $tested_count) {
                $foreground_color = "Green"
            }
            Write-Host "$accepted_count/$tested_count" -ForegroundColor $foreground_color
        }
    }
}

# process the problems to validate.
if ($null -eq $problems) {
    Write-Error "Please input the -problems to validate."
    exit
}

if (!(Test-Path ./problems -PathType Container)) {
    Write-Error "The 'problems' folder doesn't exist."
    exit
}

# loop through all the problems
foreach ($problem in $problems) {
    Write-Host "Checking problem $problem"

    if (!(Test-Path ./problems/$problem -PathType Container)) {
        Write-Error "The 'problems/$problem' folder doesn't exist."
        continue
    }

    if (!(Test-Path ./problems/$problem/io -PathType Container)) {
        Write-Error "The 'problems/$problem/io' folder doesn't exist."
        continue
    }

    # check the io
    if ($checkIo -eq $true) {
        Invoke-Io-Validation -problem $problem
    }

    # check the solutions
    if ($checkSolutions -eq $true) {
        Invoke-Solution-Validation -problem $problem
    }
}

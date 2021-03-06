<#
problems/
    $problem/
        io/
        solutions/
            *-ac.cpp
        checkers/
            *.cpp
        generators/
            descriptor.json
            *.cpp
#>

param (
    $problems,
    [switch]$checkIo = $false,
    [switch]$checkSolutions = $false,
    [switch]$generateInput = $false,
    [switch]$generateOutput = $false,
    [switch]$debugSolutions = $false,
    $solutionFilter,
    $ioSetFilter,
    $ioNumberFilter
)

function Get-Solutions-Folder {
    param ($problem)

    return "./problems/$problem/solutions"
}

function Get-Io-Folder {
    param ($problem)

    return "./problems/$problem/io"
}

function Get-Io-Sets {
    param ($problem)

    $io_folder = Get-Io-Folder -problem $problem

    return Get-ChildItem -Path "$io_folder/" `
        -Name `
        -Attributes D
}

function Get-Io {
    param ($problem, $io_set)

    $io_folder = Get-Io-Folder -problem $problem

    return Get-ChildItem -Path "$io_folder/$io_set/*.in" `
        -Name
}

function New-Or-Clear-File {
    param($path, $file)

    if (!(Test-Path "$path/$file")) {
        $x = New-Item -Path "$path/" `
            -Name "$file" `
            -ItemType "file" `
            -Value ""
        $x = $x # quick silly fix
    }
    Clear-Content "$path/$file"
}

function Invoke-Output-Generator {
    param ($problem, $solutionFilter, $ioSetFilter, $ioNumberFilter)

    $solutions_folder = Get-Solutions-Folder -problem $problem
    $io_folder = Get-Io-Folder -problem $problem

    if (!(Test-Path "$solutions_folder" -PathType Container)) {
        Wirte-Host "Found no solutions folder."
        return
    }

    $solution = $null
    if ($null -eq $solutionFilter) {
        $solutions = Get-ChildItem -Path "$solutions_folder/*-ac.cpp" `
            -Name
        if ($null -eq $solutions) {
            Write-Host "Found no solutions suffixed with '-ac' to generate the output."
            return
        }
    
        if ($solutions.GetType().Name -eq "String") {
            $solution = $solutions
        } elseif ($solutions.GetType().Name -eq "Object[]") {
            $solution = $solutions[0]
        } else {
            Write-Host "Error while finding generation solution."
            return
        }
        $solution = $solution.Split(".")[0]
    }
    else {
        $solutions = Get-ChildItem -Path "$solutions_folder/$solutionFilter.cpp" `
            -Name
        if ($null -eq $solutions) {
            Write-Host "Found no solution name $solutionFilter."
            return
        }
        $solution = $solutionFilter
    }

    Write-Host "Generating output using solution '$solution.cpp'."

    g++ "$solutions_folder/$solution.cpp" `
        -o "$solutions_folder/$solution.exe"

    New-Or-Clear-File `
        -path "$solutions_folder" `
        -file "temp.txt"

    $io_sets = Get-Io-Sets -problem $problem
    foreach ($io_set in $io_sets) {
        if ($null -ne $ioSetFilter -and $ioSetFilter -ne $io_set) {
            continue
        }

        $input_files = Get-Io -problem $problem -io_set $io_set
        $total_io_count = $input_files.length
        $index = 1
        foreach ($input_file in $input_files) {
            $input_number = $input_file.Split(".")[0]
            if ($null -ne $ioNumberFilter -and $ioNumberFilter -ne $input_number) {
                $index++
                continue
            }

            Write-Host "`rIO set #$io_set ($index/$total_io_count)." -NoNewLine

            New-Or-Clear-File `
                -path "$io_folder/$io_set" `
                -file "$input_number.out"
            Clear-Content "$solutions_folder/temp.txt"

            Get-Content "$io_folder/$io_set/$input_file" | `
                & "$solutions_folder/$solution.exe" | `
                Out-File -Encoding UTF8 "$solutions_folder/temp.txt"
            $solution_output = Get-Content "$solutions_folder/temp.txt"

            $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
            [System.IO.File]::WriteAllLines(
                "$io_folder/$io_set/$input_number.out",
                $solution_output,
                $Utf8NoBomEncoding)

            $index++
        }
        Write-Host ""
    }
}

function Invoke-Input-Generator {
    param ($problem)

    if (!(Test-Path ./problems/$problem/generators -PathType Container)) {
        return
    }

    if (!(Test-Path ./problems/$problem/generators/descriptor.json)) {
        Write-Host "File generators/descriptor.json not found."
        return
    }

    $generator_descriptor = Get-Content -Path ./problems/$problem/generators/descriptor.json | `
        ConvertFrom-Json
    foreach ($descriptor_item in $generator_descriptor.PSObject.Properties) {
        $tc_set = $descriptor_item.Name
        Write-Host "Generating input for the TC set #$tc_set"

        if (!(Test-Path ./problems/$problem/io/$tc_set)) {
            $x = New-Item -Path ./problems/$problem/io/ `
                -Name "$tc_set" `
                -ItemType "directory"
            $x = $x
        }

        $index = 1
        foreach ($tc_descriptor in $descriptor_item.Value) {
            $generator_name = $tc_descriptor.generator
            $generator_seed = $tc_descriptor.seed
            $generator_input = $tc_descriptor.input
            $generator_premade = $tc_descriptor.premade

            if($null -ne $generator_premade) {
                $index = $generator_premade.end + 1
                continue
            }

            if (!(Test-Path ./problems/$problem/io/$tc_set/$index.in)) {
                $x = New-Item -Path ./problems/$problem/io/$tc_set/ `
                    -Name "$index.in" `
                    -ItemType "file" `
                    -Value ""
                $x = $x # quick silly fix
            }
            Clear-Content ./problems/$problem/io/$tc_set/$index.in

            if ($null -eq $generator_name) {
                if ($null -ne $generator_input) {
                    # generate input
                    $input_temp = "$generator_input"

                    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
                    [System.IO.File]::WriteAllLines(
                        "./problems/$problem/io/$tc_set/$index.in",
                        $input_temp,
                        $Utf8NoBomEncoding)
                }
            } else {
                if (!(Test-Path ./problems/$problem/generators/$generator_name)) {
                    Write-Host "Generator $generator_name not found."
                    continue
                }

                g++ ./problems/$problem/generators/$generator_name `
                    -o ./problems/$problem/generators/$generator_name.exe

                # generate input
                $input_temp = "$generator_seed $generator_input" | `
                    & ./problems/$problem/generators/$generator_name.exe

                $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
                [System.IO.File]::WriteAllLines(
                    "./problems/$problem/io/$tc_set/$index.in",
                    $input_temp,
                    $Utf8NoBomEncoding)
            }

            $index++
        }
    }
}

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
            $x = New-Item -Path ./problems/$problem/checkers/ `
                -Name "temp.txt" `
                -ItemType "file" `
                -Value ""
            $x = $x # quick silly fix
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

                $foreground_color = "Green"
                if ($key.Contains("wrong")) {
                    $foreground_color = "Red"
                }
                Write-Host "$key : $value" -ForegroundColor $foreground_color
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
        $solution_name = $solution.Split(".")[0]

        g++ ./problems/$problem/solutions/$solution `
            -o ./problems/$problem/solutions/$solution.exe
        if ($debugSolutions) {
            g++ ./problems/$problem/solutions/$solution `
                -o ./problems/$problem/solutions/$solution.debug.exe `
                -DDEBUG
        }

        if (!(Test-Path ./problems/$problem/solutions/temp.txt)) {
            $x = New-Item -Path ./problems/$problem/solutions/ `
                -Name "temp.txt" `
                -ItemType "file" `
                -Value "."
            $x = $x
        }

        if ($debugSolutions -and !(Test-Path ./problems/$problem/solutions/$solution_name-debug -PathType Container)) {
            $x = New-Item -Path ./problems/$problem/solutions/ `
                -Name "$solution_name-debug" `
                -ItemType "directory"
            $x = $x
        }

        $tc_sets = Get-ChildItem -Path ./problems/$problem/io/ `
            -Name `
            -Attributes D
        foreach ($tc_set in $tc_sets) {
            Write-Host "Checking the TC set #$tc_set : " -NoNewline

            if ($debugSolutions -and !(Test-Path ./problems/$problem/solutions/$solution_name-debug/$tc_set -PathType Container)) {
                $x = New-Item -Path ./problems/$problem/solutions/$solution_name-debug/ `
                    -Name "$tc_set" `
                    -ItemType "directory"
                $x = $x
            }

            $tested_count = 0
            $accepted_count = 0

            $tcs = Get-ChildItem -Path ./problems/$problem/io/$tc_set/*.in `
                -Name
            foreach ($tc in $tcs) {
                if ($debugSolutions) {
                    if (!(Test-Path ./problems/$problem/solutions/$solution_name-debug/$tc_set/$tc.debug)) {
                        $x = New-Item -Path ./problems/$problem/solutions/$solution_name-debug/$tc_set/ `
                        -Name "$tc.debug" `
                        -ItemType "file" `
                        -Value "."
                        $x = $x
                    }
                    $debug_file_path = "./problems/$problem/solutions/$solution_name-debug/$tc_set/$tc.debug"
                    Clear-Content -Path "$debug_file_path"
                    if (!(Test-Path ./problems/$problem/solutions/$solution_name-debug/$tc_set/$tc.out)) {
                        $x = New-Item -Path ./problems/$problem/solutions/$solution_name-debug/$tc_set/ `
                            -Name "$tc.out" `
                            -ItemType "file" `
                            -Value "."
                        $x = $x
                    }
                    Clear-Content -Path "./problems/$problem/solutions/$solution_name-debug/$tc_set/$tc.out"

                    "$debug_file_path " + (Get-Content ./problems/$problem/io/$tc_set/$tc) | `
                        & ./problems/$problem/solutions/$solution.debug.exe `
                        > ./problems/$problem/solutions/$solution_name-debug/$tc_set/$tc.out
                }

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
        $x = New-Item -Path ./problems/$problem/ `
            -Name "io" `
            -ItemType "directory"
        $x = $x
    }

    # generate input
    if ($generateInput -eq $true) {
        Invoke-Input-Generator -problem $problem
    }

    # generate output
    if ($generateOutput -eq $true) {
        Invoke-Output-Generator -problem $problem `
            -solutionFilter $solutionFilter `
            -ioSetFilter $ioSetFilter `
            -ioNumberFilter $ioNumberFilter
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

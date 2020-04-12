# Problem Setting

This is a tool to help automate problem setting's common tasks, such as generating input/output files, validating input/output files
against the problem description's constraints, and validating the solutions.

## Setup

To use this tool you must run the "bon.ps1" script on a PowerShell terminal.

## Usage example

### Validating the Input

`$ ./bon.ps1 -problems liga -checkIo`

Outputs:

```
Checking problem liga
Working on checker sanity.cpp.
Checking the TC set #1
easy : 3
Checking the TC set #2
hard : 3
```

### Validating the Solutions

`$ ./bon.ps1 -problems liga -checkSolutions`

Outputs:

```
Checking problem liga
Working on solution liga-wa.cpp.
Checking the TC set #1 : 3/3
Checking the TC set #2 : 0/3
Working on solution liga.cpp.
Checking the TC set #1 : 3/3
Checking the TC set #2 : 3/3
```

# Risc-V-Log-Analyzer

Status: complete (scripts, Makefile, documentation)

A shell-based tool that analyzes RISC-V simulation log files.

## Description

`riscv-log-analyzer` reads a simulation log (for example from a RISC-V
architecture-test run), and reports:

- total number of tests, and the number of PASS / FAIL / SKIP results
- the pass rate as a percentage
- the names of all failing tests
- execution time statistics (min / max / average) when the log has timings
- a final verdict, reflected in the exit code (0 = all passed, 1 = failures)

It is written in pure Bash + standard Unix tools (`awk`, `grep`, `sed`), and is
the Module 1 capstone project of the MEDS Summer Training Programme 2026.

**Bonus features implemented:** `--compare` (regression detection), colored
output (`--color`), and an HTML report (`scripts/generate_report.sh`).

## Installation

Requirements: Linux or WSL2 (Ubuntu 22.04+), Bash 4+, GNU Make, and the
standard tools `grep`, `awk`, `sed`, `sort`.

```bash
git clone git@github.com:umarM7788/Risc-V-Log-Analyzer.git
cd Risc-V-Log-Analyzer
make setup        # verifies tools, makes scripts executable
```

## Usage

```bash
# Analyze one log (report goes to stdout)
./scripts/analyze.sh test_data/sample_fail.log

# CSV output written to a file
./scripts/analyze.sh test_data/sample_fail.log --format csv --output output/fail.csv

# Per-test details, colored output
./scripts/analyze.sh test_data/sample_fail.log --verbose --color

# Which tests passed in the old log but fail in the new one?
./scripts/analyze.sh test_data/sample_fail.log --compare test_data/sample_pass.log

# Use the exit code in scripts / CI
./scripts/analyze.sh test_data/sample_pass.log > /dev/null && echo "all good"

# Generate TXT + CSV + HTML reports for a log
./scripts/generate_report.sh test_data/sample_fail.log
```

Everything through the Makefile:

```bash
make help      # list targets
make all       # analyze every log in test_data/
make test      # verify expected results for the sample logs
make report    # write TXT, CSV and HTML reports to output/
make clean     # delete output/
```

See [docs/USAGE.md](docs/USAGE.md) for the full command reference.

## Sample output

```text
=== RISC-V Simulation Log Analysis ===
Log file: test_data/sample_fail.log
Analysis date: 2026-10-06 23:35:32

--- Results Summary ---
Total tests: 10
Passed:      7 ( 70.0%)
Failed:      2 ( 20.0%)
Skipped:     1 ( 10.0%)

--- Failed Tests ---
  1. rv32i-sll
  2. rv32i-beq

--- Timing Statistics ---
Min time:  0.42s (rv32i-nop)
Max time:  2.31s (rv32i-mul)
Avg time:  0.89s

--- Verdict: FAIL ---
Exit code: 1
```

## Project structure

```text
riscv-log-analyzer/
├── README.md
├── Makefile
├── .gitignore
├── scripts/
│   ├── analyze.sh          # main analysis script
│   ├── setup_env.sh        # environment check
│   └── generate_report.sh  # TXT / CSV / HTML report generation
├── test_data/
│   ├── sample_sim.log      # smoke run (one skip, no failures)
│   ├── sample_pass.log     # all tests pass
│   └── sample_fail.log     # failures + a skip
├── output/                 # generated reports (gitignored)
└── docs/
    └── USAGE.md
```

## Log format

```text
[2026-05-01 10:23:46] TEST PASS: rv32i-add (0.82s)
[2026-05-01 10:23:47] TEST FAIL: rv32i-sll (1.02s)
[2026-05-01 10:23:48] TEST SKIP: rv32i-srl (not supported)
```

## Git workflow

Work was done on short-lived branches (`feature/analyzer`, `feature/report`,
`feature/makefile`, `docs/readme-usage`) merged into `main` with `--no-ff`.
View the history with:

```bash
git log --oneline --graph --all
```

## Author

Umar - MEDS Cohort 4, UET Lahore

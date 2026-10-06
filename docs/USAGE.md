# RISC-V Log Analyzer - Usage Guide

## 1. Overview

`riscv-log-analyzer` is a Bash-based command-line tool for analyzing RISC-V simulation logs.

The analyzer extracts:

- Total number of tests
- Number of PASS results
- Number of FAIL results
- Number of SKIP results
- Pass rate
- Names of failed tests
- Minimum execution time
- Maximum execution time
- Average execution time
- Overall PASS/FAIL verdict

---

# 2. Running the Analyzer

The basic syntax is:

```bash
./scripts/analyze.sh <log_file>
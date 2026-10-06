#!/bin/bash

set -euo pipefail

# ============================================================
# RISC-V Log Analyzer
# ============================================================
# Usage:
#   ./analyze.sh <log_file>
#
# Options:
#   --format text|csv
#   --output <path>
#   --verbose
#   --help
# ============================================================


# ------------------------------------------------------------
# Default configuration
# ------------------------------------------------------------

FORMAT="text"
OUTPUT=""
VERBOSE=false
LOG_FILE=""


# ------------------------------------------------------------
# Display help message
# ------------------------------------------------------------

usage() {
    cat <<EOF
RISC-V Log Analyzer

Usage:
    $0 <log_file> [options]

Options:
    --format <text|csv>    Output format. Default: text
    --output <path>        Write output to a file
    --verbose              Show additional information
    --help                 Show this help message

Examples:
    $0 test_data/sample_sim.log

    $0 test_data/sample_sim.log --format csv

    $0 test_data/sample_sim.log --output output/report.txt

    $0 test_data/sample_sim.log --verbose
EOF
}


# ------------------------------------------------------------
# Display an error and terminate
# ------------------------------------------------------------

error() {
    echo "Error: $*" >&2
    exit 2
}


# ------------------------------------------------------------
# Parse command-line arguments
# ------------------------------------------------------------

while [[ $# -gt 0 ]]; do

    case "$1" in

        --format)
            if [[ $# -lt 2 ]]; then
                error "--format requires a value"
            fi

            FORMAT="$2"
            shift 2
            ;;

        --output)
            if [[ $# -lt 2 ]]; then
                error "--output requires a file path"
            fi

            OUTPUT="$2"
            shift 2
            ;;

        --verbose)
            VERBOSE=true
            shift
            ;;

        --help|-h)
            usage
            exit 0
            ;;

        --*)
            error "Unknown option: $1"
            ;;

        *)
            if [[ -n "$LOG_FILE" ]]; then
                error "Only one log file can be supplied"
            fi

            LOG_FILE="$1"
            shift
            ;;

    esac

done


# ------------------------------------------------------------
# Validate arguments
# ------------------------------------------------------------

if [[ -z "$LOG_FILE" ]]; then
    usage >&2
    exit 2
fi


if [[ ! -f "$LOG_FILE" ]]; then
    error "Log file does not exist: $LOG_FILE"
fi


if [[ ! -r "$LOG_FILE" ]]; then
    error "Log file is not readable: $LOG_FILE"
fi


if [[ "$FORMAT" != "text" && "$FORMAT" != "csv" ]]; then
    error "Invalid format '$FORMAT'. Use text or csv."
fi


# ------------------------------------------------------------
# Redirect output if --output was supplied
# ------------------------------------------------------------

if [[ -n "$OUTPUT" ]]; then

    OUTPUT_DIR=$(dirname "$OUTPUT")

    mkdir -p "$OUTPUT_DIR"

    exec > "$OUTPUT"

fi


# ------------------------------------------------------------
# Variables used during analysis
# ------------------------------------------------------------

TOTAL=0
PASS=0
FAIL=0
SKIP=0

FAILED_TESTS=()
TIMES=()


# ------------------------------------------------------------
# Process the simulation log
# ------------------------------------------------------------

process_log() {

    local line
    local status
    local details
    local test_name
    local test_time

    while IFS= read -r line || [[ -n "$line" ]]; do

        status=""
        details=""
        test_name=""
        test_time=""

        # --------------------------------------------
        # PASS
        # --------------------------------------------

        if [[ "$line" =~ ^TEST[[:space:]]+PASS:[[:space:]]+(.*)$ ]]; then

            status="PASS"
            details="${BASH_REMATCH[1]}"


        # --------------------------------------------
        # FAIL
        # --------------------------------------------

        elif [[ "$line" =~ ^TEST[[:space:]]+FAIL:[[:space:]]+(.*)$ ]]; then

            status="FAIL"
            details="${BASH_REMATCH[1]}"


        # --------------------------------------------
        # SKIP
        # --------------------------------------------

        elif [[ "$line" =~ ^TEST[[:space:]]+SKIP:[[:space:]]+(.*)$ ]]; then

            status="SKIP"
            details="${BASH_REMATCH[1]}"

        else
            continue
        fi


        # --------------------------------------------
        # Extract execution time if present
        #
        # Example:
        # rv32i-add (0.82s)
        # --------------------------------------------

        if [[ "$details" =~ ^(.*)[[:space:]]+\(([0-9]+([.][0-9]+)?)s\)$ ]]; then

            test_name="${BASH_REMATCH[1]}"
            test_time="${BASH_REMATCH[2]}"

        else

            test_name="$details"

        fi


        # Remove trailing whitespace
        test_name="$(echo "$test_name" | sed 's/[[:space:]]*$//')"


        # --------------------------------------------
        # Update counters
        # --------------------------------------------

        TOTAL=$((TOTAL + 1))

        case "$status" in

            PASS)
                PASS=$((PASS + 1))
                ;;

            FAIL)
                FAIL=$((FAIL + 1))
                FAILED_TESTS+=("$test_name")
                ;;

            SKIP)
                SKIP=$((SKIP + 1))
                ;;

        esac


        # --------------------------------------------
        # Store execution time
        # --------------------------------------------

        if [[ -n "$test_time" ]]; then
            TIMES+=("$test_time")
        fi

    done < "$LOG_FILE"
}


# ------------------------------------------------------------
# Calculate timing statistics
# ------------------------------------------------------------

calculate_timing() {

    MIN_TIME="N/A"
    MAX_TIME="N/A"
    AVG_TIME="N/A"

    if [[ ${#TIMES[@]} -gt 0 ]]; then

        read -r MIN_TIME MAX_TIME AVG_TIME < <(

            printf '%s\n' "${TIMES[@]}" |

            awk '
                BEGIN {
                    min = 999999999
                    max = 0
                    sum = 0
                    count = 0
                }

                {
                    value = $1 + 0

                    if (value < min)
                        min = value

                    if (value > max)
                        max = value

                    sum += value
                    count++
                }

                END {
                    printf "%.2f %.2f %.2f\n",
                           min,
                           max,
                           sum / count
                }
            '

        )

    fi
}


# ------------------------------------------------------------
# Calculate pass rate
# ------------------------------------------------------------

calculate_pass_rate() {

    if (( TOTAL > 0 )); then

        awk \
            -v pass="$PASS" \
            -v total="$TOTAL" \
            'BEGIN {
                printf "%.2f", (pass / total) * 100
            }'

    else

        echo "0.00"

    fi
}


# ------------------------------------------------------------
# Print human-readable report
# ------------------------------------------------------------

print_text_report() {

    local pass_rate

    pass_rate=$(calculate_pass_rate)


    echo "========================================"
    echo "       RISC-V LOG ANALYZER REPORT"
    echo "========================================"

    echo "Log file       : $LOG_FILE"

    echo
    echo "Test Summary"
    echo "------------"

    echo "Total tests    : $TOTAL"
    echo "PASS           : $PASS"
    echo "FAIL           : $FAIL"
    echo "SKIP           : $SKIP"

    echo "Pass rate      : ${pass_rate}%"


    echo
    echo "Failing Tests"
    echo "-------------"


    if (( ${#FAILED_TESTS[@]} > 0 )); then

        for test in "${FAILED_TESTS[@]}"; do
            echo "  - $test"
        done

    else

        echo "  None"

    fi


    echo
    echo "Execution Time Statistics"
    echo "-------------------------"

    echo "Minimum        : ${MIN_TIME}s"
    echo "Maximum        : ${MAX_TIME}s"
    echo "Average        : ${AVG_TIME}s"


    echo

    if (( FAIL > 0 )); then

        echo "VERDICT        : FAIL"

    else

        echo "VERDICT        : PASS"

    fi


    if [[ "$VERBOSE" == true ]]; then

        echo
        echo "Verbose Information"
        echo "-------------------"

        echo "Log size       : $(wc -c < "$LOG_FILE") bytes"
        echo "Timed tests    : ${#TIMES[@]}"

    fi

}


# ------------------------------------------------------------
# Print CSV report
# ------------------------------------------------------------

print_csv_report() {

    local pass_rate
    local verdict

    pass_rate=$(calculate_pass_rate)


    if (( FAIL > 0 )); then
        verdict="FAIL"
    else
        verdict="PASS"
    fi


    echo "category,metric,value"

    echo "summary,total_tests,$TOTAL"
    echo "summary,pass,$PASS"
    echo "summary,fail,$FAIL"
    echo "summary,skip,$SKIP"

    echo "summary,pass_rate_percent,$pass_rate"

    echo "timing,minimum_seconds,$MIN_TIME"
    echo "timing,maximum_seconds,$MAX_TIME"
    echo "timing,average_seconds,$AVG_TIME"

    echo "summary,verdict,$verdict"


    for test in "${FAILED_TESTS[@]}"; do

        # Escape quotes for CSV
        test="${test//\"/\"\"}"

        echo "failure,test,\"$test\""

    done

}


# ------------------------------------------------------------
# Main program
# ------------------------------------------------------------

process_log

calculate_timing


if [[ "$FORMAT" == "text" ]]; then

    print_text_report

else

    print_csv_report

fi


# ------------------------------------------------------------
# Exit status
#
# 0 = all tests passed
# 1 = at least one test failed
# 2 = invalid input / usage error
# ------------------------------------------------------------

if (( FAIL > 0 )); then
    exit 1
fi

exit 0
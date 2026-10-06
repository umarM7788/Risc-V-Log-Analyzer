#!/bin/bash

set -euo pipefail

# Generate both machine-readable and browser-friendly reports.

# ============================================================
# Generate Combined RISC-V Analysis Report
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ANALYZER="$SCRIPT_DIR/analyze.sh"
TEST_DATA="$PROJECT_DIR/test_data"
OUTPUT_DIR="$PROJECT_DIR/output"

TEXT_REPORT="$OUTPUT_DIR/summary_report.txt"
HTML_REPORT="$OUTPUT_DIR/summary_report.html"


# ------------------------------------------------------------
# Create output directory
# ------------------------------------------------------------

mkdir -p "$OUTPUT_DIR"


# ------------------------------------------------------------
# Generate text report
# ------------------------------------------------------------

echo "========================================" > "$TEXT_REPORT"
echo "     RISC-V LOG ANALYZER SUMMARY" >> "$TEXT_REPORT"
echo "========================================" >> "$TEXT_REPORT"

echo >> "$TEXT_REPORT"

echo "Generated: $(date)" >> "$TEXT_REPORT"

echo >> "$TEXT_REPORT"


for log_file in "$TEST_DATA"/*.log; do

    if [[ ! -f "$log_file" ]]; then
        continue
    fi

    echo >> "$TEXT_REPORT"

    echo "########################################" >> "$TEXT_REPORT"
    echo "FILE: $(basename "$log_file")" >> "$TEXT_REPORT"
    echo "########################################" >> "$TEXT_REPORT"

    echo >> "$TEXT_REPORT"


    set +e

    "$ANALYZER" "$log_file" >> "$TEXT_REPORT"

    ANALYZER_STATUS=$?

    set -e


    echo >> "$TEXT_REPORT"
    echo "Analyzer exit code: $ANALYZER_STATUS" >> "$TEXT_REPORT"

done


# ------------------------------------------------------------
# Generate HTML report
# ------------------------------------------------------------

{
    echo "<!DOCTYPE html>"
    echo "<html>"
    echo "<head>"
    echo "<meta charset=\"UTF-8\">"
    echo "<title>RISC-V Log Analyzer Report</title>"
    echo "<style>"
    echo "body { font-family: Arial, sans-serif; margin: 40px; }"
    echo "pre { background: #f4f4f4; padding: 20px; border-radius: 8px; }"
    echo "h1 { margin-bottom: 5px; }"
    echo "</style>"
    echo "</head>"
    echo "<body>"
    echo "<h1>RISC-V Log Analyzer Report</h1>"
    echo "<p>Generated: $(date)</p>"
    echo "<pre>"

    cat "$TEXT_REPORT"

    echo "</pre>"
    echo "</body>"
    echo "</html>"

} > "$HTML_REPORT"


echo
echo "Reports generated successfully:"
echo
echo "  Text : $TEXT_REPORT"
echo "  HTML : $HTML_REPORT"
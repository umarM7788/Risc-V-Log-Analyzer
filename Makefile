SHELL := /bin/bash

PROJECT_NAME := riscv-log-analyzer

ANALYZER := ./scripts/analyze.sh
SETUP := ./scripts/setup_env.sh
REPORT := ./scripts/generate_report.sh

TEST_DIR := ./test_data
OUTPUT_DIR := ./output


.PHONY: all test report clean help setup


# ============================================================
# Default target
# ============================================================

all: setup
	@echo "Running RISC-V log analyzer on all test logs..."
	@mkdir -p $(OUTPUT_DIR)
	@for file in $(TEST_DIR)/*.log; do \
		name=$$(basename "$$file" .log); \
		echo ""; \
		echo "Analyzing $$file"; \
		$(ANALYZER) "$$file" --output "$(OUTPUT_DIR)/$${name}_report.txt" || true; \
	done
	@echo ""
	@echo "Analysis complete."
	@echo "Reports are available in $(OUTPUT_DIR)/"


# ============================================================
# Run automated tests
# ============================================================

test: setup
	@echo "========================================"
	@echo "Running automated tests"
	@echo "========================================"
	@echo ""

	@echo "[1/4] Testing sample_pass.log..."
	@if $(ANALYZER) $(TEST_DIR)/sample_pass.log > /tmp/riscv_pass_test.txt; then \
		echo "[PASS] sample_pass.log exited with code 0"; \
	else \
		echo "[FAIL] sample_pass.log should have exited with code 0"; \
		exit 1; \
	fi

	@grep -q "PASS           : 4" /tmp/riscv_pass_test.txt || \
		{ echo "[FAIL] Expected 4 passing tests"; exit 1; }

	@grep -q "VERDICT        : PASS" /tmp/riscv_pass_test.txt || \
		{ echo "[FAIL] Expected PASS verdict"; exit 1; }


	@echo ""
	@echo "[2/4] Testing sample_fail.log..."
	@if $(ANALYZER) $(TEST_DIR)/sample_fail.log > /tmp/riscv_fail_test.txt; then \
		echo "[FAIL] sample_fail.log should have exited with code 1"; \
		exit 1; \
	else \
		echo "[PASS] sample_fail.log correctly exited with code 1"; \
	fi

	@grep -q "FAIL           : 1" /tmp/riscv_fail_test.txt || \
		{ echo "[FAIL] Expected 1 failed test"; exit 1; }

	@grep -q "rv32i-mul" /tmp/riscv_fail_test.txt || \
		{ echo "[FAIL] Expected rv32i-mul to be reported"; exit 1; }


	@echo ""
	@echo "[3/4] Testing CSV output..."

	@$(ANALYZER) $(TEST_DIR)/sample_sim.log --format csv > /tmp/riscv_csv_test.csv || true

	@grep -q "category,metric,value" /tmp/riscv_csv_test.csv || \
		{ echo "[FAIL] CSV header missing"; exit 1; }

	@grep -q "summary,total_tests,7" /tmp/riscv_csv_test.csv || \
		{ echo "[FAIL] CSV total test count incorrect"; exit 1; }


	@echo ""
	@echo "[4/4] Testing help option..."

	@$(ANALYZER) --help > /tmp/riscv_help_test.txt

	@grep -q "Usage:" /tmp/riscv_help_test.txt || \
		{ echo "[FAIL] Help message missing"; exit 1; }


	@echo ""
	@echo "========================================"
	@echo "All automated tests passed!"
	@echo "========================================"


# ============================================================
# Generate combined reports
# ============================================================

report: setup
	@echo "Generating reports..."
	@$(REPORT)


# ============================================================
# Remove generated files
# ============================================================

clean:
	@echo "Removing generated reports..."
	@rm -f $(OUTPUT_DIR)/*.txt
	@rm -f $(OUTPUT_DIR)/*.csv
	@rm -f $(OUTPUT_DIR)/*.html
	@rm -f /tmp/riscv_pass_test.txt
	@rm -f /tmp/riscv_fail_test.txt
	@rm -f /tmp/riscv_csv_test.csv
	@rm -f /tmp/riscv_help_test.txt
	@echo "Clean complete."


# ============================================================
# Check development environment
# ============================================================

setup:
	@$(SETUP)


# ============================================================
# Display available targets
# ============================================================

help:
	@echo ""
	@echo "RISC-V Log Analyzer"
	@echo "==================="
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "  make all      Analyze all test logs"
	@echo "  make test     Run automated tests"
	@echo "  make report   Generate combined reports"
	@echo "  make clean    Remove generated reports"
	@echo "  make setup    Check required development tools"
	@echo "  make help     Show this help message"
	@echo ""
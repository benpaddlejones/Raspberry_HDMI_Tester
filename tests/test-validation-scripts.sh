#!/bin/bash
# Comprehensive test suite for validation scripts
# Tests error handling, cleanup, and edge cases

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

echo "=================================================="
echo "Validation Scripts - Comprehensive Test Suite"
echo "=================================================="
echo ""

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test result tracking
test_result() {
    local test_name="$1"
    local result="$2"

    ((TESTS_TOTAL++))

    if [ "${result}" = "PASS" ]; then
        echo "  ✅ ${test_name}"
        ((TESTS_PASSED++))
    else
        echo "  ❌ ${test_name}"
        ((TESTS_FAILED++))
    fi
}

# Test 1: Check all scripts exist and are executable
echo "🔍 Test 1: Script Existence and Permissions"
echo "-------------------------------------------"

for script in validate-image.sh quick-validate.sh validate-release.sh qemu-test.sh; do
    if [ -f "${PROJECT_ROOT}/tests/${script}" ] && [ -x "${PROJECT_ROOT}/tests/${script}" ]; then
        test_result "${script} exists and is executable" "PASS"
    else
        test_result "${script} exists and is executable" "FAIL"
    fi
done

echo ""

# Test 2: Check validation-utils.sh
echo "🔍 Test 2: Validation Utilities"
echo "-------------------------------------------"

if [ -f "${PROJECT_ROOT}/scripts/validation-utils.sh" ]; then
    test_result "validation-utils.sh exists" "PASS"

    # Source it and check for key functions
    # shellcheck source=../scripts/validation-utils.sh
    source "${PROJECT_ROOT}/scripts/validation-utils.sh"

    for func in setup_traps check_required_commands check_disk_space setup_loop_device mount_partition validate_file_readable validate_config_setting verify_symlink; do
        if declare -f "${func}" >/dev/null; then
            test_result "Function ${func} defined" "PASS"
        else
            test_result "Function ${func} defined" "FAIL"
        fi
    done
else
    test_result "validation-utils.sh exists" "FAIL"
fi

echo ""

# Test 3: Check scripts for shellcheck compliance
echo "🔍 Test 3: ShellCheck Compliance"
echo "-------------------------------------------"

if command -v shellcheck &>/dev/null; then
    for script in scripts/validation-utils.sh tests/validate-image.sh tests/quick-validate.sh tests/validate-release.sh tests/qemu-test.sh; do
        if shellcheck -x "${PROJECT_ROOT}/${script}" 2>&1 | grep -q "^In.*line"; then
            test_result "ShellCheck: ${script}" "FAIL"
        else
            test_result "ShellCheck: ${script}" "PASS"
        fi
    done
else
    echo "  ⚠️  ShellCheck not installed, skipping syntax checks"
fi

echo ""

# Test 4: Test validation-utils functions
echo "🔍 Test 4: Validation Utilities Functionality"
echo "-------------------------------------------"

# Test check_required_commands with valid commands
if check_required_commands bash ls pwd >/dev/null 2>&1; then
    test_result "check_required_commands (valid)" "PASS"
else
    test_result "check_required_commands (valid)" "FAIL"
fi

# Test check_required_commands with invalid command
if check_required_commands nonexistent_command_12345 >/dev/null 2>&1; then
    test_result "check_required_commands (invalid) should fail" "FAIL"
else
    test_result "check_required_commands (invalid) should fail" "PASS"
fi

# Test check_disk_space
if check_disk_space "/tmp" 1 >/dev/null 2>&1; then
    test_result "check_disk_space (sufficient)" "PASS"
else
    test_result "check_disk_space (sufficient)" "FAIL"
fi

# Test with impossibly large requirement
if check_disk_space "/tmp" 999999999 >/dev/null 2>&1; then
    test_result "check_disk_space (insufficient) should fail" "FAIL"
else
    test_result "check_disk_space (insufficient) should fail" "PASS"
fi

echo ""

# Test 5: Test config validation functions
echo "🔍 Test 5: Config File Validation"
echo "-------------------------------------------"

# Create test config file
TEST_CONFIG="/tmp/test_config_$$.txt"
cat > "${TEST_CONFIG}" << 'EOF'
# This is a comment
hdmi_force_hotplug=1
# hdmi_drive=2
  hdmi_mode=16
hdmi_group=1
EOF

# Test uncommented settings
if validate_config_setting "${TEST_CONFIG}" "^[[:space:]]*hdmi_force_hotplug=1"; then
    test_result "validate_config_setting (uncommented)" "PASS"
else
    test_result "validate_config_setting (uncommented)" "FAIL"
fi

# Test commented settings should fail
if validate_config_setting "${TEST_CONFIG}" "^[[:space:]]*hdmi_drive=2"; then
    test_result "validate_config_setting (commented) should fail" "FAIL"
else
    test_result "validate_config_setting (commented) should fail" "PASS"
fi

# Test with leading whitespace
if validate_config_setting "${TEST_CONFIG}" "^[[:space:]]*hdmi_mode=16"; then
    test_result "validate_config_setting (with whitespace)" "PASS"
else
    test_result "validate_config_setting (with whitespace)" "FAIL"
fi

rm -f "${TEST_CONFIG}"

echo ""

# Test 6: Test file validation
echo "🔍 Test 6: File Validation"
echo "-------------------------------------------"

# Create test file
TEST_FILE="/tmp/test_file_$$.txt"
echo "test content" > "${TEST_FILE}"

if validate_file_readable "${TEST_FILE}"; then
    test_result "validate_file_readable (valid file)" "PASS"
else
    test_result "validate_file_readable (valid file)" "FAIL"
fi

# Test non-existent file
if validate_file_readable "/tmp/nonexistent_file_12345.txt"; then
    test_result "validate_file_readable (missing) should fail" "FAIL"
else
    test_result "validate_file_readable (missing) should fail" "PASS"
fi

# Test empty file
: > "${TEST_FILE}"
if validate_file_readable "${TEST_FILE}"; then
    test_result "validate_file_readable (empty) should fail" "FAIL"
else
    test_result "validate_file_readable (empty) should fail" "PASS"
fi

rm -f "${TEST_FILE}"

echo ""

# Test 7: Test symlink validation
echo "🔍 Test 7: Symlink Validation"
echo "-------------------------------------------"

# Create test files and symlink
TEST_TARGET="/tmp/test_target_$$.txt"
TEST_SYMLINK="/tmp/test_symlink_$$"
echo "target" > "${TEST_TARGET}"
ln -s "${TEST_TARGET}" "${TEST_SYMLINK}"

if verify_symlink "${TEST_SYMLINK}"; then
    test_result "verify_symlink (valid)" "PASS"
else
    test_result "verify_symlink (valid)" "FAIL"
fi

# Test broken symlink
rm -f "${TEST_TARGET}"
if verify_symlink "${TEST_SYMLINK}"; then
    test_result "verify_symlink (broken) should fail" "FAIL"
else
    test_result "verify_symlink (broken) should fail" "PASS"
fi

# Test regular file (not a symlink)
echo "test" > "${TEST_TARGET}"
if verify_symlink "${TEST_TARGET}"; then
    test_result "verify_symlink (regular file) should fail" "FAIL"
else
    test_result "verify_symlink (regular file) should fail" "PASS"
fi

rm -f "${TEST_SYMLINK}" "${TEST_TARGET}"

echo ""

# Test 8: Test script error handling
echo "🔍 Test 8: Script Error Handling"
echo "-------------------------------------------"

# Test validate-image.sh with missing file
if "${PROJECT_ROOT}/tests/validate-image.sh" /tmp/nonexistent.img >/dev/null 2>&1; then
    test_result "validate-image.sh (missing file) should fail" "FAIL"
else
    test_result "validate-image.sh (missing file) should fail" "PASS"
fi

# Test validate-image.sh with no arguments
if "${PROJECT_ROOT}/tests/validate-image.sh" >/dev/null 2>&1; then
    test_result "validate-image.sh (no args) should fail" "FAIL"
else
    test_result "validate-image.sh (no args) should fail" "PASS"
fi

echo ""

# Test 9: Check for common anti-patterns
echo "🔍 Test 9: Code Quality Checks"
echo "-------------------------------------------"

# Check for unquoted variables in critical sections
if grep -n '\$[A-Z_]*[^{]' "${PROJECT_ROOT}/tests/validate-image.sh" | grep -v '^\s*#' | head -1 >/dev/null 2>&1; then
    test_result "No unquoted variables (validate-image.sh)" "WARN"
else
    test_result "No unquoted variables (validate-image.sh)" "PASS"
fi

# Check all scripts source validation-utils.sh
for script in validate-image.sh quick-validate.sh validate-release.sh qemu-test.sh; do
    if grep -q "source.*validation-utils.sh" "${PROJECT_ROOT}/tests/${script}"; then
        test_result "${script} sources validation-utils.sh" "PASS"
    else
        test_result "${script} sources validation-utils.sh" "FAIL"
    fi
done

# Check all scripts call setup_traps
for script in validate-image.sh quick-validate.sh validate-release.sh qemu-test.sh; do
    if grep -q "setup_traps" "${PROJECT_ROOT}/tests/${script}"; then
        test_result "${script} calls setup_traps" "PASS"
    else
        test_result "${script} calls setup_traps" "FAIL"
    fi
done

echo ""

# Test 10: Documentation checks
echo "🔍 Test 10: Documentation"
echo "-------------------------------------------"

# Check all scripts have usage/help
for script in validate-image.sh quick-validate.sh validate-release.sh qemu-test.sh; do
    if grep -q "show_usage\|Usage:" "${PROJECT_ROOT}/tests/${script}"; then
        test_result "${script} has usage information" "PASS"
    else
        test_result "${script} has usage information" "FAIL"
    fi
done

echo ""

# Summary
echo "=================================================="
echo "Test Summary"
echo "=================================================="
echo ""
echo "Total Tests: ${TESTS_TOTAL}"
echo "Passed:      ${TESTS_PASSED}"
echo "Failed:      ${TESTS_FAILED}"
echo ""

if [ ${TESTS_FAILED} -eq 0 ]; then
    echo "✅ ALL TESTS PASSED!"
    echo ""
    echo "The validation scripts have been successfully fixed and"
    echo "all identified critical issues have been addressed."
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    echo ""
    echo "Please review the failures above and fix the issues."
    exit 1
fi

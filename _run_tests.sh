#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test function
run_test() {
    if eval "$1"; then
        echo -e "${GREEN}[PASS]${NC} $2"
    else
        echo -e "${RED}[FAIL]${NC} $2"
        exit 1
    fi
}

# Setup
echo "Setting up test environment..."
TEST_DIR="$(mktemp -d)"
cp _encrypt_files.sh _decrypt_files.sh _generate_totp.sh "$TEST_DIR/"
cd "$TEST_DIR"
mkdir test_files
cd test_files
echo "Test content 1" > test1.md
echo "Test content 2" > test2.md

# Test encryption
echo "Testing encryption..."
run_test "../_encrypt_files.sh <<< $'testpassword\ntestpassword'" "Encryption script runs without errors"
run_test "[ -f __file_mapping.gpg ]" "Mapping file is created"
run_test "ls __*.gpg | grep -v __file_mapping.gpg | wc -l | grep -q 2" "Two encrypted files are created (excluding mapping file)"

# Debugging information
echo "Directory contents after encryption:"
ls -la
echo "Encrypted files:"
ls __*.gpg

# Test decryption with correct password
echo "Testing decryption with correct password..."
run_test "../_decrypt_files.sh <<< 'testpassword'" "Decryption script runs without errors"
run_test "[ -f test1.md ] && [ -f test2.md ]" "Original files are restored"
run_test "grep -q 'Test content 1' test1.md" "Content of test1.md is correct"
run_test "grep -q 'Test content 2' test2.md" "Content of test2.md is correct"

# Remove decrypted files
rm test1.md test2.md

# Test decryption with incorrect password
echo "Testing decryption with incorrect password..."
run_test "! ../_decrypt_files.sh <<< 'wrongpassword'" "Decryption script fails with incorrect password"
run_test "[ ! -f test1.md ]" "test1.md is not created with wrong password"
run_test "[ ! -f test2.md ]" "test2.md is not created with wrong password"

# Test TOTP generation
echo "Testing TOTP generation..."
TOTP_SECRET="JBSWY3DPEHPK3PXP"
run_test "../_generate_totp.sh $TOTP_SECRET | grep -q 'Your TOTP code is:'" "TOTP script generates a code"

# Test TOTP generation with invalid secret
echo "Testing TOTP generation with invalid secret..."
INVALID_SECRET="INVALID"
run_test "! ../_generate_totp.sh $INVALID_SECRET" "TOTP script fails with invalid secret"
run_test "../_generate_totp.sh $INVALID_SECRET 2>&1 | grep -q 'Error: Invalid secret key'" "TOTP script reports invalid secret key"

# Cleanup
echo "Cleaning up..."
cd ../..
rm -rf "$TEST_DIR"

echo "All tests completed successfully!"


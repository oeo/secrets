#!/bin/bash

# Function to securely read passphrase
read_passphrase() {
    local passphrase passphrase_confirm

    while true; do
        echo -n "Enter the passphrase for encryption: " >&2
        read -s passphrase
        echo >&2

        echo -n "Confirm the passphrase: " >&2
        read -s passphrase_confirm
        echo >&2

        if [ "$passphrase" = "$passphrase_confirm" ]; then
            echo "$passphrase"
            return 0
        else
            echo "Passphrases do not match. Please try again." >&2
        fi
    done
}

# Check if there are any .md files in the current directory
if ! ls *.md 1> /dev/null 2>&1; then
    echo "Error: No .md files found in the current directory."
    exit 1
fi

# Ask for the passphrase and confirm
PASSPHRASE=$(read_passphrase)

# Verify that we got a passphrase
if [ -z "$PASSPHRASE" ]; then
    echo "Error: No passphrase provided. Exiting."
    exit 1
fi

# Create a mapping file to store original and obfuscated names
MAPPING_FILE="file_mapping.txt"
> "$MAPPING_FILE"  # Clear the mapping file if it exists

# Encrypt all .md files
for input_file in *.md; do
    # Generate a SHA-256 hash of the original filename
    hashed_name=$(echo -n "$input_file" | sha256sum | cut -d' ' -f1)
    output_file="__${hashed_name}.gpg"  # Add '__' prefix

    # Encrypt the file
    echo "$PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 \
        --symmetric --cipher-algo AES256 --s2k-mode 3 --s2k-count 65011712 \
        --s2k-digest-algo SHA512 --no-symkey-cache \
        --output "$output_file" "$input_file"

    # Check if encryption was successful
    if [ $? -eq 0 ]; then
        echo "Encryption successful: $output_file"
        # Store the mapping of original to hashed name
        echo "${input_file}:${output_file}" >> "$MAPPING_FILE"
    else
        echo "Encryption failed for: $input_file"
    fi
done

# Encrypt the mapping file
mapping_output="__file_mapping.gpg"  # Add '__' prefix to mapping file
echo "$PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 \
    --symmetric --cipher-algo AES256 --s2k-mode 3 --s2k-count 65011712 \
    --s2k-digest-algo SHA512 --no-symkey-cache \
    --output "$mapping_output" "$MAPPING_FILE"

# Remove the unencrypted mapping file
rm "$MAPPING_FILE"

echo "Encryption process completed. Filename mapping stored in $mapping_output"


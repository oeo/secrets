#!/bin/bash

# Function to securely remove files
secure_remove() {
    if command -v shred > /dev/null; then
        shred -u "$1"
    else
        rm -P "$1"
    fi
}

# Prompt for passphrase
echo "Enter the passphrase for decryption:"
read -s PASSPHRASE

# Create a temporary file to store the passphrase
PASSPHRASE_FILE=$(mktemp)
echo "$PASSPHRASE" > "$PASSPHRASE_FILE"

# Decrypt the mapping file
gpg --batch --passphrase-file "$PASSPHRASE_FILE" --decrypt __file_mapping.gpg > file_mapping.txt

# Check if decryption was successful
if [ $? -ne 0 ]; then
    echo "Failed to decrypt mapping file. Exiting."
    secure_remove "$PASSPHRASE_FILE"
    exit 1
fi

# Read the mapping file and decrypt each file
while IFS=: read -r original obfuscated; do
    echo "Decrypting: $obfuscated to $original"
    gpg --batch --passphrase-file "$PASSPHRASE_FILE" --decrypt "$obfuscated" > "$original"
    if [ $? -eq 0 ]; then
        echo "Successfully decrypted $original"
    else
        echo "Failed to decrypt $original"
    fi
done < file_mapping.txt

# Clean up
secure_remove "$PASSPHRASE_FILE"
secure_remove file_mapping.txt

echo "Decryption process completed."


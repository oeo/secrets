echo "
# markdown file encryption and obfuscation
this project encrypts all markdown (.md) files in the current directory and obfuscates their filenames for added privacy.

oh, it excludes readme.md too, so you have to run this.

## features
- encrypts all .md files in the current directory
- obfuscates filenames using md5 hash
- uses strong gpg encryption (aes256, sha512)
- creates a mapping file to track original and obfuscated filenames
- encrypts the mapping file for security

### usage: view readme
yarn readme

### usage: encrypt all .md files
yarn encrypt

### usage: decrypt all gpg files
yarn decrypt

### usage: generate a totp code
yarn totp 'totpcodehere'

### usage: run test suite
yarn test
"

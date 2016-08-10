#!/bin/bash

# Generate Localizable.strings
find -E . -iregex '.*\.(m|h|mm)$' \
    -not -path "./UnzipKitTests*" \
    -print0 \
| xargs -0 genstrings -o Resources/en.lproj

# Define file and temp file
LOCALIZE=./Resources/en.lproj/Localizable.strings
UTF8=./Resources/en.lproj/LocalizableUTF8.txt

# Convert file (UTF-16) to temp (UTF-8)
iconv -f UTF-16LE -t UTF-8 $LOCALIZE >$UTF8

# Replace all \\n tokens in the temp file with a newline (used in comments)
sed -i "" 's_\\\\n_\
_g' $UTF8

# Convert the temp file back to UTF-16 as the original file
iconv -f UTF-8 -t UTF-16LE $UTF8 >$LOCALIZE

# Check for missing comments in the UTF8 file, showing the violating lines
MISSING=$(grep -A 1 'engineer' $UTF8 | sed '/*\/$/ s_.*__')

# Remove the temp file
rm $UTF8

# If there were missing comments
if [ -n "$MISSING" ]; then
	echo "Comments are missing for:"

	#Print output, putting line breaks back in and indenting each line
	echo $MISSING  | sed 's:-- :\
:' | sed 's/^/&   /g'

	# Return non-zero to signal an error
	exit 1
fi
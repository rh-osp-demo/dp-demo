
# Check if the user provided a string as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <string1>"
    exit 1
fi

# Get the replacement string from the command line argument
replacement_string=$1

# Replace "uuid" with the provided string in all files excluding the script itself
for file in *; do
    if [ "$file" != "replace_UUID.sh" ] && [ -f "$file" ]; then
        # Use sed to replace "uuid" with the provided string in each file
        sed -i "s/uuid/$replacement_string/g" "$file"
    fi
done

echo "Replacement complete."
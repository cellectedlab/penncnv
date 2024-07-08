#!/bin/bash

# Directory where the .txt files are located
directory="C:\Users\felix\Documents\test"

# Loop through each .txt file in the directory
for file in "$directory"/*.txt; do
    # Ensure the file exists and is not empty
    if [[ -s "$file" ]]; then
        # Extract the 16th column name from the header row
        column_name=$(awk -F '\t' 'NR==1 {print $16}' "$file")
        
        # Check if column_name is not empty
        if [[ -n "$column_name" ]]; then
            # Create a new filename using the column name
            new_filename="$directory/${column_name}.txt"
            
            # Rename the file
            mv "$file" "$new_filename"
            
            echo "Renamed $file to $new_filename"
        else
            echo "16th column not found in $file"
        fi
    else
        echo "$file is empty or does not exist."
    fi
done

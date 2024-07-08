#!/bin/bash

# Check if input file and output directory are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_directory>"
    exit 1
fi

# Input file (large data file)
input_file="$1"

# Output directory where chunk files will be stored
output_directory="$2"
mkdir -p "$output_directory"  # Ensure output directory exists, create if not

# Number of universal columns (always the first 10 columns)
num_universal_columns=10

# Determine total number of columns in the input file
total_columns=$(head -n 1 "$input_file" | awk -F '\t' '{print NF}')

# Calculate the number of chunks based on the remaining columns
num_chunks=$(( (total_columns - num_universal_columns) / 6 ))

# Loop through each chunk
for (( i = 0; i <= num_chunks; i++ )); do
    # Calculate the start and end columns for the current chunk
    start_column=$((num_universal_columns + i * 6 + 1))
    end_column=$((start_column + 5))

    # Extract columns: first 10 universal columns + 6 consecutive columns
    awk -v start=$start_column -v end=$end_column -v num_universal=$num_universal_columns 'BEGIN{FS=OFS="\t"} {
        for (i = 1; i <= num_universal; i++) {
            printf "%s%s", $i, (i < num_universal || start <= NF ? OFS : ORS)
        }
        for (i = start; i <= end && i <= NF; i++) {
            printf "%s%s", $i, (i < end && i < NF ? OFS : ORS)
        }
    }' "$input_file" > "$output_directory/chunk_${start_column}_${end_column}.txt"

    echo "Created $output_directory/chunk_${start_column}_${end_column}.txt"
done


# Loop through each .txt file in the output directory
for file in "$output_directory"/*.txt; do
    # Ensure the file exists and is not empty
    if [[ -s "$file" ]]; then
        # Extract the 16th column name from the header row
        column_name=$(awk -F '\t' 'NR==1 {print $16}' "$file")

        # Check if column_name is not empty
        if [[ -n "$column_name" ]]; then
            # Remove the trailing ".Log R Ratio" from the column name
            cleaned_column_name=$(echo "$column_name" | sed 's/\.Log R Ratio$//')

            # Create a new filename using the cleaned column name
            new_filename="$output_directory/${cleaned_column_name}.txt"

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

# Combined output file where all individual PennCNV outputs will be stored
output_file="$output_directory/penncnv_bookmarks.out"

# Ensure the combined output file starts empty
echo -n > "$output_file"

# Array of input files (assuming all .txt files in the output directory)
inputs=("$output_directory"/*.txt)

# Loop through each input file
for input_file in "${inputs[@]}"; do
    echo "Running PennCNV for input file: $input_file"

    # Extract the filename without extension to use as part of the output
    filename=$(basename "$input_file" .txt)

    # Run the PennCNV command and append output to individual and combined output files
    perl detect_cnv.pl -hmm C:\\penncnv.latest\\penncnv\\lib\\hhall.hmm \
                       -pfb C:\\penncnv.latest\\penncnv\\lib\\hhall.hg18.pfb \
                       -minsnp 10 -test -conf -tabout -coord \
                       -out "$output_directory/$filename.out" "$input_file"

    # Check if the command executed successfully
    if [ $? -eq 0 ]; then
        echo "Successfully processed $input_file"
        # Append individual output to combined output file
        cat "$output_directory/$filename.out" >> "$output_file"
    else
        echo "Error processing $input_file"
    fi
done

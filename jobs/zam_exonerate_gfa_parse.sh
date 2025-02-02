#!/bin/bash
#SBATCH --account=pi-jkoc
#SBATCH --partition=lab-colibri
#SBATCH --qos=pi-jkoc
#SBATCH --job-name=zam_exon_gfaparse
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=7-00:00:00
#SBATCH --mail-user=snbogan@ucsc.edu
#SBATCH --mail-type=ALL
#SBATCH --output=zam_exon_gfaparse%A_%a.out
#SBATCH --error=zam_exon_gfaparse%A_%a.err
#SBATCH --array=1-48

# Load necessary modules (if needed)
module load miniconda3
conda activate exonerate

# Move to wd
cd /hb/home/snbogan/PolarFish/haplo_afp/gfa_parse/l_dearborni/csvs

# Directory containing fasta files
FASTA_DIR="/hb/home/snbogan/PolarFish/haplo_afp/gfa_parse/l_dearborni/iterations"
FASTA_FILES=($(ls $FASTA_DIR/*.fasta))

# Get the current fasta file for this array task
FASTA_FILE=${FASTA_FILES[$SLURM_ARRAY_TASK_ID - 1]}
BASENAME=$(basename $FASTA_FILE .fasta)

# Output GFF file
OUTPUT_GFF="/hb/home/snbogan/PolarFish/haplo_afp/gfa_parse/l_dearborni/gffs/${BASENAME}_afp_exonerate.gff"

# Run exonerate with filtering for two-exon genes
exonerate --model protein2genome \
  --query /hb/home/snbogan/PolarFish/haplo_afp/gfa_parse/Mamericanus_AFP.txt \
  --target $FASTA_FILE \
  --showtargetgff TRUE \
  --showquerygff FALSE \
  --showalignment FALSE \
  --maxintron 10000 \
  > $OUTPUT_GFF

# Count the number of two-exon annotations
TWO_EXON_GENES=$(awk '
    /# --- START OF GFF DUMP ---/ { in_block = 1; exon_count = 0; gene_found = 0 }
    /# --- END OF GFF DUMP ---/ {
        if (gene_found && exon_count == 2) count++
        in_block = 0
    }
    in_block && $3 == "gene" { gene_found = 1 }
    in_block && $3 == "exon" { exon_count++ }
    END { print count }
' $OUTPUT_GFF)

# Save the results to a temporary file
echo "$BASENAME,$FASTA_FILE,$TWO_EXON_GENES" >> "${BASENAME}_results.csv"

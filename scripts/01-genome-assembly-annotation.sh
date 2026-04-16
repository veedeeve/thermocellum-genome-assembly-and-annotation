#!/usr/bin/env bash
set -Eeuo pipefail
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

cd "$(dirname "$0")"
source config.sh 

# ####################################
# 1. Download (SRA: SRR15202685)
####################################

log "Starting download for $SRA_ACCESSION ..."

prefetch "$SRA_ACCESSION" --output-directory "$RAW_DATA_DIR" > "$LOGS_DIR/01_prefetch.log" 2>&1
fasterq-dump "$RAW_DATA_DIR/$SRA_ACCESSION/$SRA_ACCESSION.sra" --split-files -O "$RAW_DATA_DIR" --threads "$THREADS" > "$LOGS_DIR/02_fasterq_dump.log" 2>&1
gzip "$RAW_DATA_DIR/$SRA_ACCESSION"*.fastq

# Move & Rename
mv "$RAW_DATA_DIR/${SRA_ACCESSION}_1.fastq.gz" "$READ1"
mv "$RAW_DATA_DIR/${SRA_ACCESSION}_2.fastq.gz" "$READ2"

rm -r "$RAW_DATA_DIR/$SRA_ACCESSION"

log "Completed download for $SRA_ACCESSION"

####################################
# 2. FastQC 
####################################

log "Running FastQC on raw reads ..."

fastqc "$READ1" "$READ2" -o "$FASTQC_RAW_DIR" > "$LOGS_DIR/03_fastqc_raw.log" 2>&1

log "Completed FastQC"

####################################
# 3. Trimmomatic + QC
####################################

log "Running Trimmomatic on raw reads ..."

trimmomatic PE -threads 8 "$READ1" "$READ2" \
"$TRIMMED_R1_PAIRED"  "$TRIMMED_R1_UNPAIRED" \
"$TRIMMED_R2_PAIRED"  "$TRIMMED_R2_UNPAIRED" \
ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 \
TRAILING:20 \
SLIDINGWINDOW:4:25 \
MINLEN:50 \
> "$LOGS_DIR/04_trimmomatic.log" 2>&1

log "Completed Trimmomatic"

log "Running FastQC on trimmed reads ..."

fastqc "$TRIMMED_R1_PAIRED" "$TRIMMED_R2_PAIRED" \
-o "$FASTQC_TRIMMED_DIR" > "$LOGS_DIR/05_fastqc_trimmed.log" 2>&1

log "FastQC on trimmed reads complete"

####################################
# 4. Assembly (SPAdes)
####################################

log "Running SPAdes (default mode) ..."

spades.py -1 "$TRIMMED_R1_PAIRED" \
-2 "$TRIMMED_R2_PAIRED" \
-t "$THREADS" \
-m "$MEMORY" \
-o "$SPADES_DEFAULT_DIR" \
> "$LOGS_DIR/06_spades_default.log" 2>&1

log "Running SPAdes (careful mode) ..."

spades.py --careful -1 "$TRIMMED_R1_PAIRED" \
-2 "$TRIMMED_R2_PAIRED" \
-t "$THREADS" \
-m "$MEMORY" \
-o "$SPADES_CAREFUL_DIR" \
> "$LOGS_DIR/07_spades_careful.log" 2>&1

log "Assembly (default & careful) complete"

####################################
# 5. Download References
####################################

log "Downloading references ..."

# Reference annotated genome
wget -O "$REF_GFF" https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/015/865/GCF_000015865.1_ASM1586v1/GCF_000015865.1_ASM1586v1_genomic.gff.gz \
> "$LOGS_DIR/08_ref_gff.log" 2>&1

# Reference genome
wget -O "$REF_FNA" https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/015/865/GCF_000015865.1_ASM1586v1/GCF_000015865.1_ASM1586v1_genomic.fna.gz \
> "$LOGS_DIR/09_ref_fna.log" 2>&1

log "References downloaded"

####################################
# 6. QUAST
####################################

log "Starting QUAST ..."

quast -o "$QUAST_DIR" \
-R "$REF_FNA" \
-g "$REF_GFF" \
-l "Spades_Default, Spades_Careful" "$SPADES_DEFAULT_DIR/scaffolds.fasta" "$SPADES_CAREFUL_DIR/scaffolds.fasta" \
> "$LOGS_DIR/10_quast.log" 2>&1

log "QUAST complete"

####################################
# 7. Annotation (Prokka)
####################################

log "Starting Prokka ..."

prokka "$SPADES_CAREFUL_DIR/scaffolds.fasta" \
--outdir "$PROKKA_DIR" \
--prefix "$SPECIES" \
--genus "$GENUS" \
--species "$SPECIES" \
--strain "$STRAIN" \
--cpus 4 \
> "$LOGS_DIR/11_prokka.log" 2>&1

log "Prokka annotation completed"

####################################
# 8. BLASTP
####################################

log "Starting BLASTP ..."

# Download Swiss-Prot to compare predicted proteins
wget -O "$SWISSPROT_DIR/uniprot_sprot.fasta.gz" ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz \
> "$LOGS_DIR/12_swissprot_download.log" 2>&1

gunzip "$SWISSPROT_DIR/uniprot_sprot.fasta.gz"

makeblastdb -in "$SWISSPROT_FASTA" \
-dbtype prot \
-out "$SWISSPROT_DB" \
> "$LOGS_DIR/13_makeblastdb.log" 2>&1

blastp -query "$PROKKA_DIR/thermocellum.faa" \
-db "$SWISSPROT_DB" \
-out "$BLASTP_OUT" \
-evalue 1e-5 \
-outfmt 6 \
-num_threads 4 \
> "$LOGS_DIR/14_blastp.log" 2>&1

log "BLASTP completed"


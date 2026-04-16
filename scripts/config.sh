#!/usr/bin/env bash

# Gets project root automatically 
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

############################
# DIRECTORIES
############################

RAW_DATA_DIR="$PROJECT_ROOT/raw_data"
METADATA_DIR="$PROJECT_ROOT/metadata"
ANALYSIS_DIR="$PROJECT_ROOT/analysis"
LOGS_DIR="$PROJECT_ROOT/logs"

THREADS=8
MEMORY=14

SRA_ACCESSION="SRR15202685"

############################
# RAW READS + QC
############################

READ1="$RAW_DATA_DIR/thermocellum_R1.fastq.gz"
READ2="$RAW_DATA_DIR/thermocellum_R2.fastq.gz"

############################
# TRIMMING + QC
############################

TRIMMED_DIR="$ANALYSIS_DIR/trimmed"
TRIMMED_R1_PAIRED="$TRIMMED_DIR/thermocellum_R1_paired.fastq.gz"
TRIMMED_R1_UNPAIRED="$TRIMMED_DIR/thermocellum_R1_unpaired.fastq.gz"
TRIMMED_R2_PAIRED="$TRIMMED_DIR/thermocellum_R2_paired.fastq.gz"
TRIMMED_R2_UNPAIRED="$TRIMMED_DIR/thermocellum_R2_unpaired.fastq.gz"

FASTQC_RAW_DIR="$ANALYSIS_DIR/fastqc_raw"
FASTQC_TRIMMED_DIR="$ANALYSIS_DIR/fastqc_trimmed"

SPADES_CAREFUL_DIR="$ANALYSIS_DIR/spades_careful"
SPADES_DEFAULT_DIR="$ANALYSIS_DIR/spades_default"

REFERENCE_DIR="$ANALYSIS_DIR/reference"
REF_GFF="$REFERENCE_DIR/thermocellum_anno_ref_genome.gff.gz"
REF_FNA="$REFERENCE_DIR/thermocellum_ref_genome.fna.gz"

QUAST_DIR="$ANALYSIS_DIR/quast_output"

PROKKA_DIR="$ANALYSIS_DIR/prokka_annotation"
PROKKA_PREFIX="thermocellum"

SWISSPROT_DIR="$ANALYSIS_DIR/annot_swissprot"
SWISSPROT_FASTA="$SWISSPROT_DIR/uniprot_sprot.fasta"
SWISSPROT_DB="$SWISSPROT_DIR/swissprot_db"

BLASTP_OUT="$ANALYSIS_DIR/blastp_results.out"

GENUS="Clostridium"
SPECIES="thermocellum"
STRAIN="LL1789"
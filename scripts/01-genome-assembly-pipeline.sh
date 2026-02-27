#!/bin/bash

# Directory
# /users/vydang/thermo_genome_assem_anno

# ---------- 1) Download Files (SRR Accession: SRR15202685)  ----------
mkdir -p ~/thermo_genome_assem_anno/data
prefetch SRR15202685 --output-directory ~/thermo_genome_assem_anno/data
fasterq-dump ~/thermo_genome_assem_anno/data/SRR15202685/SRR15202685.sra --split-files -O ~/thermo_genome_assem_anno/data --threads 8
gzip ~/thermo_genome_assem_anno/data/SRR15202685*.fastq

#Rename files
mv SRR15202685_1.fastq.gz thermocellum_R1.fastq.gz
mv SRR15202685_2.fastq.gz thermocellum_R2.fastq.gz

# ---------- 2) Quality Control  ----------
mkdir -p ~/thermo_genome_assem_anno/results/fastqc/before-trim
fastqc ~/thermo_genome_assem_anno/data/thermocellum_R*.fastq.gz -o ~/thermo_genome_assem_anno/results/fastqc/before-trim

# ---------- 3) Trimming  ----------
mkdir -p ~/thermo_genome_assem_anno/data/trimmed
trimmomatic PE -threads 8 ~/thermo_genome_assem_anno/data/thermocellum_R1.fastq.gz ~/thermo_genome_assem_anno/data/thermocellum_R2.fastq.gz \
~/thermo_genome_assem_anno/data/trimmed/thermocellum_R1_paired.fastq.gz  ~/thermo_genome_assem_anno/data/trimmed/thermocellum_R1_unpaired.fastq.gz \
~/thermo_genome_assem_anno/data/trimmed/thermocellum_R2_paired.fastq.gz  ~/thermo_genome_assem_anno/data/trimmed/thermocellum_R2_unpaired.fastq.gz \
ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 \
TRAILING:20 \
SLIDINGWINDOW:4:25 \
MINLEN:50

# ---------- 4) Quality Control  ----------
mkdir -p ~/thermo_genome_assem_anno/results/fastqc/after-trim
fastqc ~/thermo_genome_assem_anno/data/trimmed/thermocellum_R*_paired.fastq.gz -o ~/thermo_genome_assem_anno/results/fastqc/after-trim

# ---------- 5) Assemble Genome - Spades  ----------
#spades careful - default k-mer (21, 33, 55, 77)
spades.py --careful -1 ~/thermo_genome_assem_anno/data/trimmed/thermocellum_R1_paired.fastq.gz \
-2 ~/thermo_genome_assem_anno/data/trimmed/thermocellum_R2_paired.fastq.gz \
-t 8 \
-m 14 \
-o ~/thermo_genome_assem_anno/results/spades_careful

#spades default
spades.py -1 ~/thermo_genome_assem_anno/data/trimmed/thermocellum_R1_paired.fastq.gz \
-2 ~/thermo_genome_assem_anno/data/trimmed/thermocellum_R2_paired.fastq.gz \
-t 8 \
-m 14 \
-o ~/thermo_genome_assem_anno/results/spades_default

# ---------- 6) Download Reference Genome  ----------
#download reference annotated genome
wget -P ~/thermo_genome_assem_anno/data/ https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/015/865/GCF_000015865.1_ASM1586v1/GCF_000015865.1_ASM1586v1_genomic.gff.gz
mv ~/thermo_genome_assem_anno/data/GCF_000015865.1_ASM1586v1_genomic.gff.gz ~/thermo_genome_assem_anno/data/thermocellum_anno_ref_genome.gff.gz

#download reference genome
wget -P ~/thermo_genome_assem_anno/data/ https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/015/865/GCF_000015865.1_ASM1586v1/GCF_000015865.1_ASM1586v1_genomic.fna.gz 
mv ~/thermo_genome_assem_anno/data/GCF_000015865.1_ASM1586v1_genomic.fna.gz ~/thermo_genome_assem_anno/data/thermocellum_ref_genome.fna.gz

# ---------- 7) Quality Control - QUAST  ----------
quast -o ~/thermo_genome_assem_anno/results/quast_output -R ~/thermo_genome_assem_anno/data/thermocellum_ref_genome.fna.gz \
-g ~/thermo_genome_assem_anno/data/thermocellum_anno_ref_genome.gff.gz \
-l "Spades_Default, Spades_Careful" ~/thermo_genome_assem_anno/results/spades_default/scaffolds.fasta ~/thermo_genome_assem_anno/results/spades_careful/scaffolds.fasta 

# ---------- 8) Structural Annotation - PROKKA  ----------
mkdir -p ~/thermo_genome_assem_anno/results/prokka_annotation
prokka ~/thermo_genome_assem_anno/results/spades_careful/scaffolds.fasta \
--outdir ~/thermo_genome_assem_anno/results/prokka_annotation \
--prefix thermocellum \
--genus Clostridium \
--species thermocellum \
--strain DSM1313 \
--cpus 4

# ---------- 9) BLASTP  ----------
mkdir -p ~/thermo_genome_assem_anno/results/annot_swissprot
# Download Swiss-Prot to compare predicted proteins
wget -P ~/thermo_genome_assem_anno/results/annot_swissprot ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz
gunzip ~/thermo_genome_assem_anno/results/annot_swissprot/uniprot_sprot.fasta.gz

makeblastdb -in ~/thermo_genome_assem_anno/results/annot_swissprot/uniprot_sprot.fasta \
-dbtype prot \
-out swissprot/swissprot_db
blastp -query ~/thermo_genome_assem_anno/results/prokka_annotation/thermocellum.faa \
-db swissprot/swissprot_db \
-out ~/thermo_genome_assem_anno/results/blastp_results.out \
-evalue 1e-5 \
-outfmt 6 \
-num_threads 4










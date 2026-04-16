# Thermocellum Genome Assembly & Annotation - Methodology

## Dataset
- **Sample:** *Clostridium thermocellum* DSM1313
- **Accession:** SRR15202685 (SRA)
- **Sequencing type:** Paired-end short-read Illumina
- **Reference genome:** GCF_000015865.1_ASM1586v1 (NCBI)

## 1. Data Download
- Reads retrieved from NCBI SRA using `prefetch` + `fasterq-dump`
  - `prefetch` downloads the compressed `.sra` file for reliable transfer on HPC systems
  - `fasterq-dump` converts the `.sra` file to paired FASTQ files with `--split-files` to separate R1 and R2 reads
  - Output compressed with `gzip` to reduce storage footprint

## 2. Quality Control (Pre-trimming)
- Raw read quality assessed using `FastQC` before trimming
  - Evaluates per-base quality scores, GC content, adapter contamination, and sequence duplication levels

## 3. Adapter & Quality Trimming
- Adapters trimmed and low-quality bases removed using `Trimmomatic` in paired-end mode
  - Only paired output files retained for assembly — unpaired reads discarded
- Parameters used: `ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 TRAILING:20 SLIDINGWINDOW:4:25 MINLEN:50`
  - `ILLUMINACLIP:TruSeq3-PE.fa:2:30:10` — removes TruSeq paired-end adapters
  - `TRAILING:20` — removes low-quality bases from the 3' end of reads (quality < 20)
  - `SLIDINGWINDOW:4:25` — stricter than standard (4:20); quality threshold raised to 25 for a bacterial assembly
  - `MINLEN:50` — longer minimum read length than RNA-seq (36 bp) to ensure reads are long enough for reliable k-mer based assembly

 ## 4. Quality Control (Post-trimming)
- Post-trimming FastQC run on paired output files only
  - Confirms adapter removal and quality improvement before assembly

## 5. Genome Assembly
- De novo genome assembly performed using `SPAdes` in two modes for comparison:
  - **SPAdes Careful** (`--careful`) — reduces mismatches and indels in the final assembly using additional error correction; preferred for downstream annotation as it produces a cleaner assembly
  - **SPAdes Default** — run in parallel for direct comparison via QUAST to quantify the benefit of `--careful` mode
- Default k-mer sizes used: 21, 33, 55, 77 — SPAdes automatically selects optimal k-mers for the data
- `scaffolds.fasta` used as the assembly output for downstream steps
 
## 6. Reference Genome Download
- Reference genome (GCF_000015865.1_ASM1586v1) and annotation (GFF) downloaded from NCBI for use in QUAST evaluation
  - Provides a ground truth for assessing assembly completeness and accuracy
  - Both `.fna` (sequence) and `.gff` (annotation) files downloaded to enable gene-level assembly evaluation in QUAST

## 7. Assembly Evaluation (QUAST)
- Assembly quality assessed using `QUAST` with the reference genome and annotation provided
  - Both SPAdes Default and SPAdes Careful assemblies evaluated simultaneously for direct comparison (`-l "Spades_Default, Spades_Careful"`)
  - `-R` reference genome used to calculate genome fraction covered by the assembly
  - `-g` annotation GFF used to assess how many annotated genes are captured in the assembly
- SPAdes Careful selected for downstream annotation based on QUAST results

## 8. Structural Annotation (Prokka)
- Structural annotation performed using `Prokka` on the SPAdes Careful scaffolds
  - Rapid prokaryotic genome annotator that predicts CDS, tRNA, rRNA, and other features
- Taxonomy metadata provided to improve annotation accuracy:
  - `--genus Clostridium` and `--species thermocellum` guide Prokka's internal database search
  - `--strain DSM1313` records the specific strain for accurate annotation metadata
- Prokka outputs a `.faa` file (predicted protein sequences) used directly as input for BLASTP

## 9. Functional Annotation (BLASTP vs Swiss-Prot)
- Predicted protein sequences from Prokka (`.faa`) compared against the Swiss-Prot database using `BLASTP`
  - Swiss-Prot chosen over TrEMBL or NCBI-nr for its manually curated, high-confidence entries 
  - Swiss-Prot database downloaded directly from UniProt and converted to a BLAST-searchable database using `makeblastdb`
  - `-dbtype prot` specifies a protein database
- BLASTP search parameters:
  - `-evalue 1e-5` — standard E-value cutoff for homology-based annotation; filters low-confidence hits
  - `-outfmt 6` — tabular output format for efficient parsing and filtering of results
  - `-num_threads 4` — parallel processing for faster search against the full Swiss-Prot database

**Post-BLASTP Filtering (Python)**
- Raw BLASTP results filtered using a three-criteria approach:
  - `evalue < 1e-5` — confidence threshold
  - `pident >= 50` — minimum 50% amino acid identity to the Swiss-Prot hit
  - `coverage >= 80%` — alignment must cover at least 80% of the query sequence
   ~24% annotation rate — prioritizes high-confidence hits 
- **Coverage calculation:** alignment coverage computed relative to the longest alignment per query (`length / max(length) * 100`), not the full query sequence length
- **Top hit selection:** results sorted by E-value ascending, then bitscore descending — for ties in E-value, the hit with the highest bitscore (most information content) is preferred; one top hit retained per query sequence
- **Swiss-Prot ID parsing:** `sseqid` field follows the format `db|accession|entry_name` — split on `|` to extract accession and entry name for downstream annotation and unique accession export



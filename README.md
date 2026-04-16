# *C. thermocellum* Genome Assembly & Annotation

A de novo genome assembly and annotation workflow for *Clostridium thermocellum*, an anaerobic bacterium of interest for lignocellulosic biomass degradation and biofuel production.

---

## Project Overview

Contains bash scripts for de novo genome assembly and structural/functional annotation of *Clostridium thermocellum*. The pipeline processes raw sequencing reads through QC, assembly, polishing, and annotation.

**Note:** This workflow is currently implemented as modular bash scripts. Migration to Nextflow is planned 

---

## Strain Information
 
| Field | Details |
|---|---|
| Organism | *Clostridium thermocellum* |
| Strain | *LL1798* |
| Reference Genome | *NCBI Accession: `GCA_000015865`* |
| Sequencing Platform | *Illumina NextSeq 500* |
| Read Type | *Paired (500 bp pair-end)* |
| NCBI SRA | *SRR15202685* |
 
---

The pipeline includes: 
1. SRA retrieval (SRR15202685)
2. Quality Control (FastQC)
3. Read Trimming (Trimmomatic)
4. De Novo Assembly (SPAdes)
5. Assembly Evaluation (QUAST)
6. Structural Annotation (Prokka)
7. Homology-Based Functional Annotation (BLASTP vs Swiss-Prot)
8. Functional Refinement

## Key Findings
- A 3.49 Mb draft genome was assembled across 286 contigs, consistent with expected genome size for C. thermocellum.
- Prokka identified:
   - 2,981 coding sequences (CDS)
   - 55 tRNAs
   - 4 rRNAs
   - 1 tmRNA  
- 726 high-confidence matches (24.35%) in BLASTP against Swiss-Prot

---

## File Structure
```
thermo-genome-assembly-annotation/
├── raw_data/
├── metadata/
├── analysis/
│   ├── fastqc_raw/
│   ├── fastqc_trimmed/
│   ├── spades_default/
│   ├── spades_careful/
│   ├── reference/
│   ├── quast/
│   ├── prokka_annotation/
│   ├── annot_swissprot/
├── scripts/
│   ├── config.sh
│   ├── 01-genome-assembly.sh
│   ├── 02-gene-annotation.py
├── logs/
├── docs/
├── environment.yml
└── README.md
```

---

## Results 

**Assembly Statistics (Spades_Careful):**

- N50:  `36,968 bp`  
- Total assembly length: `3,453,625`  
- Genome fraction: `85.687%`  
- Misassemblies: `75`  

**Annotation (Prokka & SwissProt):**
- Predicted coding sequences (CDS): `2980`
- rRNAs and tRNAs detected: `4 rRNA, 52 tRNA`
- Annotated coding sequence: `738`
- Functional annotations via SwissProt: `~24.77%`

**Top SwissProt Protein Hits**

| Accession | E-Value | % Identity | BitScore |
| :-------: | :------: | :-------: | :-------: |
| A3DIJ8 | 1.32E-58 | 94.737 | 179.0|
| A3DIK9 | 0.0 | 100 | 509.0 |
| A3DIL4 | 0.0 | 100 | 741.0 |
| Q9UYB2 | 3.13E-121 | 54.277 | 355.0 |
| P37351 | 3.25E-53 | 57.931 | 169.0 |

---

## Usage

Install mamba following: [Github: miniforge][https://github.com/conda-forge/miniforge]

### Setup Environment
```bash
micromamba create -f environment.yml
micromamba activate assembly_annotation_env
```

### If needed, update paths of the config.sh 
```bash
nano scripts/config.sh
```

### Run script
```bash
bash scripts/01-genome-assembly-annotation.sh
python scripts/02-gene-annotation.py --blast_file analysis/blastp_results.out 
```

---

## Discussion
This project implemented an end-to-end de novo genome assembly and annotation pipeline for Clostridium thermocellum using short-read sequencing data. 

### Assembly
The genome assembly results demonstrated that both SPAdes default and SPAdes careful pipeline produced comparable assemblies. The genome fraction was nearly identical, indicating that both approaches were able to recover a similar proportion of the reference genome. However, the SPAdes careful assembly resulted in fewer contigs (100 vs 104) and higher NGA50 value (36,968 bp vs 36,572 bp), suggesting improved continuity and longer assembled regions. SPAdes careful assembly was selected to conduct annotation due to its improved contiguity while maintaining comparabe accuracy.

### Annotation

Prokka predicted 2,980 coding sequences along with tRNA and rRNA genes, aligning with expected bacterial genome architecture. Functional annotation using BLASTP against the curated Swiss-Prot database, followed by stringent filtering, identified 726 high-confidence protein matches (24% of CDS). This conservative annotation rate reflects the limited but high-confidence nature of Swiss-Prot and prioritizes reliability over coverage.

Overall, the workflow demonstrates a reproducible genome assembly and functional annotation strategy, producing a biologically consistent draft genome suitable for downstream comparative and metabolic analysis.

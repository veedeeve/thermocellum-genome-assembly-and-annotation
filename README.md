# Genome Assembly of Clostridium Thermocellum
This project demonstrates a complete workflow for **de novo genome assembly and annotation** of *Clostridium thermocellum* using publicly available sequencing data (SRA: SRR15202685). The pipeline includes **SRA retrieval, QC, trimming, SPAdes assembly, QUAST evaluation, Prokka annotation, and BLASTP validation**.

## Results 
**Assembly Statistics (Spades_Careful):**
- N50:  `37,784 bp`
- Total assembly length: `3,470,289`
- Genome fraction: `85.958%`
- Misassemblies: `83`

**Annotation (Prokka):**
- Predicted coding sequences (CDS): `2988`
- rRNAs and tRNAs detected: `8 rRNA, 54 tRNA`
- Functional annotations via SwissProt: `68.41%`

**Top SwissProt Protein Hits**
| Accession | E-Value | % Identity | BitScore |
| :-------: | :------: | :-------: | :-------: |
| A3DIJ8 | 1.32E-58 | 94.737 | 179.0|
| A3DIK9 | 0.0 | 100 | 509.0 |
| A3DIL4 | 0.0 | 100 | 741.0 |
| Q9UYB2 | 3.13E-121 | 54.277 | 355.0 |
| P37351 | 3.25E-53 | 57.931 | 169.0 |

## Tools Used
- **Data Retrieval:** `sra-tools`
- **Quality Control:** `Trimmomatic`
- **Quality Check:** `FastQC`, `QUAST`
- **Assembly:** `SPAdes`
- **Annotation:** `Prokka`
- **Functional annotation:** `BLASTp`
- **Data processing:** `awk`, `pandas`

## Workflow
<img width="685" height="355" alt="genome_assembly_workflow" src="https://github.com/user-attachments/assets/0e74e709-0b21-4726-ad46-3692a1022880" />

## Reproducibility
All steps were executed in a Bioconda-managed environment. 
See genome_assembly_pipeline.sh for full workflow execution.

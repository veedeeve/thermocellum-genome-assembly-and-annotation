#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Annotate genes on SwissProt database
"""
import pandas as pd
import sys
import argparse
from pathlib import Path

# ---------------------
# ARGUMENT PARSING
# ---------------------

parser = argparse.ArgumentParser(
    description = "Annotate sequence")

parser.add_argument(
    "--blast_file",
    required = True,
    help = "Path to blast .out file")

args = parser.parse_args()

blast_out = Path(args.blast_file)

# Load BLAST output 
columns = ["qseqid", "sseqid", "pident", "length", "mismatch", "gapopen",
            "qstart", "qend", "sstart", "send", "evalue", "bitscore"]
blast_df = pd.read_csv(blast_out, sep="\t", header=None, names=columns)

# Filter for significant hits (e.g., e-value < 1e-5)
blast_df['coverage'] = blast_df['length'] / blast_df.groupby('qseqid')['length'].transform('max') * 100
blast_filtered = blast_df[
                    (blast_df['evalue'] < 1e-5) & 
                    (blast_df['pident'] >= 50) & 
                    (blast_df['coverage'] >= 80)
                    ].copy()

# Select top hit for each query sequence
top_hits = blast_filtered.sort_values(['qseqid', 'evalue','bitscore'], ascending=[True, True, False]).groupby("qseqid", as_index=False ).first()

top_hits.to_csv("analysis/blastp_top_hits.csv", index=False)

# Calculate percent of proteins with significant hits
total_cds = 2980  # from Prokka
annotated = len(top_hits)
percent = (annotated / total_cds) * 100

print(f"Annotated CDS: {annotated}")
print(f"Percent annotated: {percent:.2f}%")

# Extract database and accession from sseqid
split_cols = top_hits['sseqid'].astype(str).str.split('|', expand=True)
top_hits['db'] = split_cols[0]
if split_cols.shape[1] > 1:
    top_hits["accession"] = split_cols[1]
else:
    top_hits["accession"] = pd.NA

if split_cols.shape[1] > 2:
    top_hits["entry_name"] = split_cols[2]
else:
    top_hits["entry_name"] = pd.NA

# Keep unique accessions
unique_accessions = top_hits.drop_duplicates(subset=['accession'])

# Save unique accessions for further annotation
unique_accessions.to_csv("analysis/unique_accessions.csv", index=False)

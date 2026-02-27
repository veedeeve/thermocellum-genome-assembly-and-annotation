import pandas as pd

# Load BLAST output 
blast_file = "results/blastp_results.out"
columns = ["qseqid", "sseqid", "pident", "length", "mismatch", "gapopen",
            "qstart", "qend", "sstart", "send", "evalue", "bitscore"]
blast_df = pd.read_csv(blast_file, sep="\t", header=None, names=columns)

# Filter for significant hits (e.g., e-value < 1e-5)
blast_df['coverage'] = blast_df['length'] / blast_df.groupby('qseqid')['length'].transform('max') * 100
blast_filtered = blast_df[(blast_df['evalue'] < 1e-5) & (blast_df['pident'] >= 50) & (blast_df['coverage'] >= 80)]

# Select top hit for each query sequence
top_hits = blast_filtered.sort_values(['qseqid', 'evalue','bitscore'], ascending=[True, True, False])
top_hits = top_hits.groupby('qseqid').first().reset_index()
top_hits.to_csv("results/blastp_top_hits.csv", index=False)

# Calculate percent of proteins with significant hits
total_cds = 2981  # from Prokka
annotated = len(top_hits)
percent = (annotated / total_cds) * 100
print(f"Annotated CDS: {annotated}")
print(f"Percent annotated: {percent:.2f}%")

# Extract database and accession from sseqid
parts = top_hits['sseqid'].str.split('|', expand=True)
top_hits['db'] = parts[0]
top_hits['accession'] = parts[1]
top_hits['entry_name'] = parts[2]

# Keep unique accessions
unique_accessions = top_hits.drop_duplicates(subset=['accession'])

# Save unique accessions for further annotation
unique_accessions.to_csv("results/unique_accessions.csv", index=False)
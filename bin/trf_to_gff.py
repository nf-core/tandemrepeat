#!/usr/bin/env python3
"""
Convert TRF output (.dat) to GFF3 format.

TRF .dat format:
Sequence: chr1
Parameters: 2 7 7 80 10 24 500

12469 12499 5 6.2 6 95 0 27 16 54 36 15 1.66 TAACA chr1
12502 12530 5 5.8 6 91 0 23 13 43 33 13 1.66 TATTA chr1
...

Output GFF3 format:
chr1    TRF     tandem_repeat   12469   12499   6.2     +       .       ID=trf_1;Name=TAACA;Period=5;Copies=6.2;Consensus=TAACA
"""

import argparse
import sys
import re
from pathlib import Path


def parse_trf_dat(input_file):
    """
    Parse TRF .dat file and yield repeat records.
    """
    current_sequence = None
    parameters = None

    with open(input_file, 'r') as f:
        for line in f:
            line = line.strip()

            # Skip empty lines
            if not line:
                continue

            # Parse sequence header
            if line.startswith('Sequence:'):
                current_sequence = line.split(':', 1)[1].strip()
                continue

            # Parse parameters line
            if line.startswith('Parameters:'):
                parameters = line.split(':', 1)[1].strip()
                continue

            # Parse data lines (should have 15+ columns)
            parts = line.split()
            if len(parts) >= 15:
                # TRF output columns:
                # 0: Start
                # 1: End
                # 2: Period Size
                # 3: Copy Number
                # 4: Consensus Size
                # 5: Percent Matches
                # 6: Percent Indels
                # 7: Score
                # 8: A count
                # 9: C count
                # 10: G count
                # 11: T count
                # 12: Entropy
                # 13: Consensus sequence
                # 14+: Sequence name
                try:
                    record = {
                        'seqid': parts[14] if len(parts) > 14 else current_sequence,
                        'start': int(parts[0]),
                        'end': int(parts[1]),
                        'period': int(parts[2]),
                        'copies': float(parts[3]),
                        'consensus_size': int(parts[4]),
                        'percent_matches': float(parts[5]),
                        'percent_indels': float(parts[6]),
                        'score': int(parts[7]),
                        'a_count': int(parts[8]),
                        'c_count': int(parts[9]),
                        'g_count': int(parts[10]),
                        't_count': int(parts[11]),
                        'entropy': float(parts[12]),
                        'consensus': parts[13],
                    }
                    yield record
                except (ValueError, IndexError) as e:
                    print(f"Warning: Could not parse line: {line}", file=sys.stderr)
                    continue


def write_gff3(records, output_file, sample_name):
    """
    Write records to GFF3 format.
    """
    with open(output_file, 'w') as f:
        # Write header
        f.write("##gff-version 3\n")
        f.write(f"# Source: Tandem Repeats Finder (TRF)\n")
        f.write(f"# Sample: {sample_name}\n")
        f.write(f"# Tool: nf-core/tandemrepeat\n")

        # Write records
        for i, record in enumerate(records, 1):
            attributes = (
                f"ID=trf_{i};"
                f"Name={record['consensus']};"
                f"Period={record['period']};"
                f"Copies={record['copies']:.2f};"
                f"ConsensusSize={record['consensus_size']};"
                f"PercentMatches={record['percent_matches']:.1f};"
                f"PercentIndels={record['percent_indels']:.1f};"
                f"Score={record['score']};"
                f"Entropy={record['entropy']:.2f};"
                f"BaseCounts=A:{record['a_count']},C:{record['c_count']},G:{record['g_count']},T:{record['t_count']}"
            )

            gff_line = "\t".join([
                record['seqid'],
                "TRF",                          # source
                "tandem_repeat",                # type
                str(record['start']),
                str(record['end']),
                str(record['score']),           # score
                ".",                            # strand (TRF doesn't specify)
                ".",                            # phase
                attributes
            ])
            f.write(gff_line + "\n")


def main():
    parser = argparse.ArgumentParser(
        description="Convert TRF output to GFF3 format"
    )
    parser.add_argument(
        "--input", "-i",
        required=True,
        help="Input TRF .dat file"
    )
    parser.add_argument(
        "--output", "-o",
        required=True,
        help="Output GFF3 file"
    )
    parser.add_argument(
        "--sample", "-s",
        default="sample",
        help="Sample name for header"
    )

    args = parser.parse_args()

    # Parse input
    records = list(parse_trf_dat(args.input))

    if not records:
        print(f"Warning: No records found in {args.input}", file=sys.stderr)
        # Create empty GFF with header
        Path(args.output).write_text("##gff-version 3\n# No tandem repeats found\n")
        return

    # Write output
    write_gff3(records, args.output, args.sample)
    print(f"Converted {len(records)} records to {args.output}")


if __name__ == "__main__":
    main()

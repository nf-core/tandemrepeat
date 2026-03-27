#!/usr/bin/env python

import os
import sys
import errno
import argparse
import logging
import pandas as pd

# Create a logger
logging.basicConfig(
    format="%(name)s - %(asctime)s %(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)


def make_dir(path):
    if len(path) > 0:
        try:
            os.makedirs(path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise exception


def print_error(error, context="Line", context_str=""):
    error_str = "ERROR: Please check samplesheet -> {}".format(error)
    if context != "" and context_str != "":
        error_str = "ERROR: Please check samplesheet -> {}\n{}: '{}'".format(
            error, context.strip(), context_str.strip()
        )
    print(error_str)
    sys.exit(1)


def check_samplesheet(file_in, file_out):
    """
    This function checks that the samplesheet follows the following structure:

    sample,fasta
    SAMPLE1,/path/to/genome1.fa
    SAMPLE2,/path/to/genome2.fa.gz

    For an example see:
    https://raw.githubusercontent.com/nf-core/test-datasets/tandemrepeat/samplesheet/test.csv
    """

    sample_mapping_dict = {}
    with open(file_in, "r") as fin:

        # Check the header
        MIN_COLS = 2
        HEADER = ["sample", "fasta"]
        header = [x.strip('"') for x in fin.readline().strip().split(",")]
        if header[: len(HEADER)] != HEADER:
            print(
                "ERROR: Please check samplesheet header -> {} != {}".format(
                    ",".join(header), ",".join(HEADER)
                )
            )
            sys.exit(1)

        # Check the samplesheet entries
        for line in fin:
            lspl = [x.strip().strip('"') for x in line.strip().split(",")]

            # Check valid number of columns per row
            if len(lspl) < len(HEADER):
                print_error(
                    "Invalid number of columns (minimum = {})!".format(len(HEADER)),
                    "Line",
                    line,
                )

            num_cols = len([x for x in lspl if x])
            if num_cols < MIN_COLS:
                print_error(
                    "Invalid number of populated columns (minimum = {})!".format(MIN_COLS),
                    "Line",
                    line,
                )

            # Get sample and fasta info
            sample = lspl[0]
            fasta = lspl[1]

            # Check sample name entries
            if sample:
                if sample.find(" ") != -1:
                    print_error(
                        "Sample entry contains spaces!", "Line", line
                    )
            else:
                print_error(
                    "Sample entry has not been specified!", "Line", line
                )

            # Check fasta file extension
            if fasta:
                if fasta.find(" ") != -1:
                    print_error(
                        "Fasta file contains spaces!", "Line", line
                    )
                if not fasta.endswith((".fa", ".fasta", ".fa.gz", ".fasta.gz")):
                    print_error(
                        "Fasta file does not have extension '.fa', '.fasta', '.fa.gz' or '.fasta.gz'!",
                        "Line",
                        line,
                    )

            # Create sample mapping dictionary
            sample_info = [sample, fasta]
            if sample not in sample_mapping_dict:
                sample_mapping_dict[sample] = [sample_info]
            else:
                if sample_info in sample_mapping_dict[sample]:
                    print_error(
                        "Samplesheet contains duplicate rows!", "Line", line
                    )
                else:
                    sample_mapping_dict[sample].append(sample_info)

    # Write validated samplesheet with appropriate columns
    if len(sample_mapping_dict) > 0:
        out_dir = os.path.dirname(file_out)
        make_dir(out_dir)
        with open(file_out, "w") as fout:
            fout.write(",".join(["sample", "fasta", "single_end"]) + "\n")
            for sample in sorted(sample_mapping_dict.keys()):
                # Assume single-end for fasta files
                for idx, val in enumerate(sample_mapping_dict[sample]):
                    fout.write(",".join(val + ["True"]) + "\n")
    else:
        print_error(
            "No entries to process!", "Samplesheet:={}".format(file_in)
        )


def main(args=None):
    args = parse_args(args)
    check_samplesheet(args.FILE_IN, args.FILE_OUT)


def parse_args(args=None):
    Description = "Reformat nf-core/tandemrepeat samplesheet file and check its contents."
    Epilog = "Example usage: python check_samplesheet.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input samplesheet file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    return parser.parse_args(args)


if __name__ == "__main__":
    sys.exit(main())

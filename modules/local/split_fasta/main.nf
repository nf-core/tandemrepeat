process SPLIT_FASTA {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::seqkit=2.6.1"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.6.1--h9ee0642_0' :
        'biocontainers/seqkit:2.6.1--h9ee0642_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.fa"), emit: chromosomes
    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    # Split multi-FASTA into individual chromosome files
    seqkit split \
        --by-id \
        --two-pass \
        --out-dir ./split \
        $args \
        $fasta

    # Move and rename files
    for f in ./split/*; do
        filename=\$(basename "\$f")
        # Remove suffix after first space in header for clean filename
        clean_name=\$(echo "\$filename" | sed 's/\\.fa//; s/ .*//; s/[[:space:]]//g')
        mv "\$f" "\${clean_name}.fa"
    done

    rmdir ./split 2>/dev/null || true

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(seqkit version | sed 's/seqkit v//')
    END_VERSIONS
    """

    stub:
    """
    touch chr1.fa chr2.fa chr3.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: 2.6.1
    END_VERSIONS
    """
}

process SAMPLESHEET_CHECK {
    tag "$samplesheet"
    label 'process_single'

    conda "conda-forge::python=3.12.0 conda-forge::pandas=2.2.1"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-5fdc2c8f3ff67a45a8b1e259f7725563f798444d:1e6624d1f069078c45ef3c02a34f23315c2c0c2c-0' :
        'biocontainers/mulled-v2-5fdc2c8f3ff67a45a8b1e259f7725563f798444d:1e6624d1f069078c45ef3c02a34f23315c2c0c2c-0' }"

    input:
    path samplesheet

    output:
    path '*.csv'       , emit: csv
    path 'versions.yml', emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    check_samplesheet.py \
        $samplesheet \
        samplesheet.valid.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW: Validate and prepare input samplesheet
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow INPUT_CHECK {

    take:
    samplesheet // channel: [ val(meta), file(fasta) ]

    main:

    ch_versions = Channel.empty()

    //
    // MODULE: Validate and check input samplesheet
    //
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { row ->
            def meta = [:]
            meta.id = row.sample
            meta.single_end = row.single_end.toBoolean()
            return [ meta, file(row.fasta) ]
        }
        .set { ch_fasta }

    ch_versions = ch_versions.mix(SAMPLESHEET_CHECK.out.versions)

    emit:
    fasta    = ch_fasta       // channel: [ val(meta), file(fasta) ]
    versions = ch_versions    // channel: [ path(versions.yml) ]
}

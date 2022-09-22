--- 
$namespaces: 
  edam: "http://edamontology.org/"
  s: "http://schema.org/"
$schemas: 
  - "http://edamontology.org/EDAM_1.16.owl"
  - "https://schema.org/version/latest/schemaorg-current-https.jsonld"
class: Workflow
cwlVersion: v1.2
doc: |
    This workflow will run a QC on the reads and then ti will
    do the RNA annotation of them.
inputs: 
  5.8s_pattern: string
  5s_pattern: string
  CGC_postfixes: "string[]"
  EggNOG_data_dir: 
    - string
    - Directory
  EggNOG_db: 
    - string?
    - File?
  EggNOG_diamond_db: 
    - string?
    - File?
  HMM_database: string
  HMM_database_dir: 
    - string
    - Directory?
  HMM_gathering_bit_score: boolean
  HMM_omit_alignment: boolean
  InterProScan_applications: "string[]"
  InterProScan_databases: 
    - string
    - Directory
  InterProScan_outputFormat: "string[]"
  Uniref90_db_txt: 
    - string
    - File
  antismash_geneclusters_txt: File?
  assemble: 
    default: false
    type: boolean
  base_correction: 
    default: false
    type: boolean
  both_reads: "string[]?"
  cgc_chunk_size: int
  contigs_file: 
    type: File?
  cut_right: 
    default: true
    type: boolean
  detect_adapter_for_pe: 
    default: false
    type: boolean
  diamond_databaseFile: 
    - string
    - File
  diamond_header: string
  diamond_maxTargetSeqs: int
  disable_trim_poly_g: 
    default: true
    type: boolean
  filename: 
    default: diamond-subwf-test
    type: string
  force_polyg_tail_trimming: 
    default: false
    type: boolean
  forward_reads: File?
  func_ann_names_hmmer: string
  func_ann_names_ips: string
  funct_annot: 
    default: false
    type: boolean
  go_config: 
    - string
    - File
  gp_flatfiles_path: 
    - string?
    - Directory?
  graphs: 
    - string
    - File
  hmmsearch_header: string
  ips_header: string
  ko_file: 
    - string
    - File
  lsu_db: 
    secondaryFiles: 
      - .mscluster
    type: File
  lsu_label: string
  lsu_otus: 
    - string
    - File
  lsu_tax: 
    - string
    - File
  memory: int?
  min-contig-len: int
  min_length_required: 
    default: 100
    type: int
  ncrna_tab_file: 
    type: File?
  other_ncRNA_models: "string[]"
  outputFormat: 
    default: "6"
    type: string
  overlap_len_require: 
    default: 3
    type: int
  overrepresentation_analysis: 
    default: false
    type: boolean
  pathways_classes: 
    - string
    - File
  pathways_names: 
    - string
    - File
  phred: 
    default: "33"
    type: string
  protein_chunk_size_IPS: int
  protein_chunk_size_eggnog: int
  protein_chunk_size_hmm: int
  qualified_phred_quality: 
    type: int?
  reverse_reads: File?
  rfam_model_clans: 
    - string
    - File
  rfam_models: 
    type: 
      - 
        items: 
          - string
          - File
        type: array
  rna_prediction_reads_level: 
    default: true
    type: boolean
  run_qc: 
    default: true
    type: boolean
  ssu_db: 
    secondaryFiles: 
      - .mscluster
    type: File
  ssu_label: string
  ssu_otus: 
    - string
    - File
  ssu_tax: 
    - string
    - File
  strand: 
    default: both
    type: string
  taxon_infer_contigs_level: 
    default: false
    type: boolean
  threads: 
    default: 2
    type: int
  unqualified_percent_limit: 
    type: int?
outputs: 
  contigs: 
    outputSource: assembly/contigs
    type: File?
  count_faa: 
    outputSource: cgc/count_faa
    type: int
  fastp_filtering_json_report: 
    outputSource: qc_and_merge/fastp_filtering_json
    pickValue: all_non_null
    type: "File[]?"
  filtered_fasta: 
    outputSource: qc_and_merge/filtered_fasta
    pickValue: all_non_null
    type: "File[]?"
  hashsum_paired: 
    outputSource: qc_and_merge/input_files_hashsum_paired
    pickValue: all_non_null
    type: "File[]?"
  m_filtered_fasta: 
    outputSource: qc_and_merge/m_filtered_fasta
    type: File
  m_qc_stats: 
    outputSource: qc_and_merge/m_qc_stats
    type: Directory?
  ncRNA: 
    outputSource: rna-prediction/ncRNA
    type: File?
  no_tax_flag_file: 
    outputSource: rna-prediction/optional_tax_file_flag
    type: File?
  predicted_faa: 
    format: "edam:format_1929"
    outputSource: cgc/predicted_proteins
    type: File
  predicted_ffn: 
    format: "edam:format_1929"
    outputSource: cgc/predicted_seq
    type: File
  qc-statistics: 
    outputSource: qc_and_merge/qc-statistics
    pickValue: all_non_null
    type: "Directory[]?"
  qc_summary: 
    outputSource: qc_and_merge/qc_summary
    pickValue: all_non_null
    type: "File[]?"
  rna-count: 
    outputSource: rna-prediction/rna-count
    type: File?
  sequence-categorisation_folder: 
    outputSource: rna-prediction/sequence_categorisation_folder
    type: Directory?
  taxonomy-summary_folder: 
    outputSource: rna-prediction/taxonomy-summary_folder
    type: Directory?
requirements: 
  InlineJavascriptRequirement: {}
  MultipleInputFeatureRequirement: {}
  ScatterFeatureRequirement: {}
  StepInputExpressionRequirement: {}
  SubworkflowFeatureRequirement: {}
? "s:author"
: "Haris Zafeiropoulos"
? "s:copyrightHolder"
: "European Marine Biological Resource Centre"
? "s:license"
: "https://www.apache.org/licenses/LICENSE-2.0"
steps: 
  assembly: 
    in: 
      assemble: assemble
      forward_reads: 
        source: qc_and_merge/filtered_fasta
        valueFrom: "$(self[0])"
      memory: memory
      min-contig-len: min-contig-len
      reverse_reads: 
        source: qc_and_merge/filtered_fasta
        valueFrom: "$(self[1])"
      threads: threads
    out: 
      - contigs
      - options
    run: conditionals/megahit.cwl
    when: "$(inputs.assemble != false)"
  cgc: 
    in: 
      chunk_size: cgc_chunk_size
      funct_annot: funct_annot
      input_fasta: 
        pickValue: first_non_null
        source: 
          - assembly/contigs
          - contigs_file
          - forward_reads
      maskfile: 
        pickValue: first_non_null
        source: 
          - rna-prediction/ncRNA
          - ncrna_tab_file
          - forward_reads
      postfixes: CGC_postfixes
    out: 
      - predicted_proteins
      - predicted_seq
      - count_faa
    run: subworkflows/assembly/cgc/CGC-subwf.cwl
    when: "$(inputs.funct_annot == true)"
  qc_and_merge: 
    doc: "The rna prediction step is based on pre-processed and merged reads. This step aims at the pre-processing and merging the raw reads so its output can be used for the rna prediction step."
    in: 
      base_correction: base_correction
      both_reads: both_reads
      cut_right: cut_right
      detect_adapter_for_pe: detect_adapter_for_pe
      disable_trim_poly_g: disable_trim_poly_g
      force_polyg_tail_trimming: force_polyg_tail_trimming
      forward_reads: forward_reads
      min_length_required: min_length_required
      overlap_len_require: overlap_len_require
      overrepresentation_analysis: overrepresentation_analysis
      qualified_phred_quality: qualified_phred_quality
      reverse_reads: reverse_reads
      run_qc: run_qc
      threads: threads
      unqualified_percent_limit: unqualified_percent_limit
    out: 
      - m_qc_stats
      - m_filtered_fasta
      - qc-statistics
      - qc_summary
      - qc-status
      - input_files_hashsum_paired
      - fastp_filtering_json
      - filtered_fasta
    run: conditionals/qc.cwl
    when: "$(inputs.run_qc != false)"
  rna-prediction: 
    doc: "Returns taxonomic profile of the sample based on the prediction of rna reads and their assignment"
    in: 
      5.8s_pattern: 5.8s_pattern
      5s_pattern: 5s_pattern
      filtered_fasta: qc_and_merge/m_filtered_fasta
      lsu_db: lsu_db
      lsu_label: lsu_label
      lsu_otus: lsu_otus
      lsu_tax: lsu_tax
      other_ncRNA_models: other_ncRNA_models
      rfam_model_clans: rfam_model_clans
      rfam_models: rfam_models
      rna_prediction_reads_level: rna_prediction_reads_level
      run_qc: run_qc
      ssu_db: ssu_db
      ssu_label: ssu_label
      ssu_otus: ssu_otus
      ssu_tax: ssu_tax
    out: 
      - sequence_categorisation_folder
      - taxonomy-summary_folder
      - rna-count
      - compressed_files
      - optional_tax_file_flag
      - ncRNA
    run: conditionals/rna-prediction.cwl
    when: "$(inputs.run_qc != false && inputs.rna_prediction_reads_level != false)"

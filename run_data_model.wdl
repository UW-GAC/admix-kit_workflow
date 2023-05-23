version 1.0

import "sim_admixed.wdl" as tasks

workflow run_data_model {
    input {
        Array[Map[String, File]] pgen
        Array[String] lanc
        Array[String] chrom
        Array[String] pop
        Array[Float] admix_prop
        String build
        Int n_indiv
        Int n_gen
        Int run_id = 1
        String source_data = "1000 Genomes"
    }

    call tasks.sim_data_model {
        input: pgen = pgen,
               psam = pgen[1]["psam"],
               lanc = lanc,
               chrom = chrom,
               pop = pop,
               admix_prop = admix_prop,
               build = build,
               n_indiv = n_indiv,
               n_gen = n_gen,
               run_id = run_id,
               source_data = source_data
    }
    
    output {
        Map[String, File] table_files = sim_data_model.table_files
    }

    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"

    }
}

version 1.0

import "sim_admixed.wdl" as tasks

workflow run_admix {
    input {
        Array[File] pgen
        Array[File] psam
        Array[File] pvar
        Array[Float] admix_prop
        String build
        Int chrom
        Int n_indiv
        Int n_gen
    }

    call tasks.admix_simu {
         input: pgen = pgen,
                psam = psam,
                pvar = pvar,
                admix_prop = admix_prop,
                build = build,
                chrom = chrom,
                n_indiv = n_indiv,
                n_gen = n_gen
    }

    output {
        File out_pgen = admix_simu.out_pgen
        File out_psam = admix_simu.out_psam
        File out_pvar = admix_simu.out_pvar
        File out_lanc = admix_simu.out_lanc
    }

    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"
    }
}

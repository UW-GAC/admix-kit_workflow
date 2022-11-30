version 1.0

import "sim_admixed.wdl" as tasks

workflow subset_pop {
    input {
        File pgen
        File psam
        File pvar
        String pop
    }

    call tasks.subset_pop_indiv {
         input: pgen = pgen,
                psam = psam,
                pvar = pvar,
                pop = pop
    }

    output {
        File out_pgen = subset_pop_indiv.out_pgen
        File out_psam = subset_pop_indiv.out_psam
        File out_pvar = subset_pop_indiv.out_pvar
    }

    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"
    }
}

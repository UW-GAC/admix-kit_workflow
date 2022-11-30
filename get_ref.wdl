version 1.0

import "sim_admixed.wdl" as tasks

workflow get_ref {
    input {
        String build
    }

    call tasks.get_1kg_ref {
         input: build = build
    }

    output {
        File out_pgen = get_1kg_ref.out_pgen
        File out_psam = get_1kg_ref.out_psam
        File out_pvar = get_1kg_ref.out_pvar
    }

    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"
    }
}

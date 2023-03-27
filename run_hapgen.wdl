version 1.0

import "sim_admixed.wdl" as tasks

workflow run_hapgen {
    input {
        Map[String, File] pgen
        String build
        Int n_indiv
    }

    call tasks.hapgen2 {
         input: pgen = pgen,
                build = build,
                n_indiv = n_indiv
    }

    output {
        File out_pgen = hapgen2.out_pgen
        File out_psam = hapgen2.out_psam
        File out_pvar = hapgen2.out_pvar
    }

    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"
    }
}

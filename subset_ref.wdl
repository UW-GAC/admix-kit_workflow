version 1.0

import "sim_admixed.wdl" as tasks

workflow subset_ref {
    input {
        File pgen
        File psam
        File pvar
        String build
        Int chrom
    }

    call tasks.subset_hapmap3 {
         input: pgen = pgen,
                psam = psam,
                pvar = pvar,
                build = build,
                chrom = chrom
    }

    output {
        File out_pgen = subset_hapmap3.out_pgen
        File out_psam = subset_hapmap3.out_psam
        File out_pvar = subset_hapmap3.out_pvar
    }

    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"
    }
}

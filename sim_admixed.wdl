version 1.0

workflow sim_admixed {
    input {
        Array[String] pops
        Array[Float] admix_prop
        String build
        Int chrom
        Int n_indiv
        Int n_gen
    }

    
}


task get-1kg-ref {
    input {
        String build
    }

    command {
        admix get-1kg-ref --dir ref --build ${build}
    }

    output {
        File pgen = "ref/pgen/all_chr.pgen"
        File psam = "ref/pgen/all_chr.psam"
        File pvar = "ref/pgen/all_chr.pvar"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.0"
    }
}


task subset-hapmap3 {
    input {
        File pgen
        File psam
        File pvar
        String build
        Int chrom
    }

    String pfile = sub(pgen, "\\.pgen$", "")

    command {
        admix subset-hapmap3 \
            --pfile ${pfile} \
            --build ${build} \
            --chrom ${chrom} \
            --out_pfile hm3_chr${chrom}
    }

    output {
        File pgen = "hm3_chr${chrom}.pgen"
        File psam = "hm3_chr${chrom}.psam"
        File pvar = "hm3_chr${chrom}.pvar"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.0"
    }
}


task subset-pop-indiv {
    input {
        File pgen
        File psam
        File pvar
        String pop
    }

    String pfile = sub(pgen, "\\.pgen$", "")
    String prefix = basename(pgen, ".pgen")

    command {
        admix subset-pop-indiv \
            --pfile ${pfile} \
            --pop ${pop} \
            --out ${pop}.indiv
        plink2 --pfile ${pfile} \
            --keep ${pop}.indiv \
            --make-pgen \
            --out ${prefix}_${pop}
    }

    output {
        File pgen = "${prefix}_${pop}.pgen"
        File psam = "${prefix}_${pop}.psam"
        File pvar = "${prefix}_${pop}.pvar"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.0"
    }
}


task hapgen2 {
    input {
        File pgen
        File psam
        File pvar
        String build
        Int chrom
        Int n_indiv
    }

    String pfile = sub(pgen, "\\.pgen$", "")
    String prefix = basename(pgen, ".pgen")

    command {
        admix hapgen2 \
            --pfile ${pfile} \
            --chrom ${CHROM} \
            --n-indiv ${N_INDIV} \
            --out ${prefix}.hapgen2 \
            --build ${BUILD}
    }

    output {
        File pgen = "${prefix}.hapgen2.pgen"
        File psam = "${prefix}.hapgen2.psam"
        File pvar = "${prefix}.hapgen2.pvar"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.0"
    }
}


task admix-simu {
    input {
        Array[File] pgen
        Array[File] psam
        Array[File] pvar
        Array[Float] admix_prop
        String build
        Int n_indiv
        Int n_gen
    }

    Array[String] pfile = sub(pgen, "\\.pgen$", "")

    command {
        admix admix-simu \
            --pfile-list "[${sep=',', pfile}]" \
            --admix-prop "[${sep=',', admix_prop}]" \
            --n-indiv ${n_indiv} \
            --n-gen ${n_gen} \
            --build ${build} \
            --out admix
    }

    output {
        File pgen = "admix.pgen"
        File psam = "admix.psam"
        File pvar = "admix.pvar"
        File lanc = "admix.lanc"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.0"
    }
}

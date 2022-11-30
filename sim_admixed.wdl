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
    
    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"
    }
}


task get_1kg_ref {
    input {
        String build
    }

    command {
        admix get-1kg-ref --dir ref --build ${build}
    }

    output {
        File out_pgen = "ref/pgen/all_chr.pgen"
        File out_psam = "ref/pgen/all_chr.psam"
        File out_pvar = "ref/pgen/all_chr.pvar"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.0"
        memory: "16GB"
        disks: "local-disk 32 SSD"
    }
}


task subset_hapmap3 {
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
        File out_pgen = "hm3_chr${chrom}.pgen"
        File out_psam = "hm3_chr${chrom}.psam"
        File out_pvar = "hm3_chr${chrom}.pvar"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.0"
    }
}


task subset_pop_indiv {
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
        File out_pgen = "${prefix}_${pop}.pgen"
        File out_psam = "${prefix}_${pop}.psam"
        File out_pvar = "${prefix}_${pop}.pvar"
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
            --chrom ${chrom} \
            --n-indiv ${n_indiv} \
            --out ${prefix}.hapgen2 \
            --build ${build}
    }

    output {
        File out_pgen = "${prefix}.hapgen2.pgen"
        File out_psam = "${prefix}.hapgen2.psam"
        File out_pvar = "${prefix}.hapgen2.pvar"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.0"
    }
}


task admix_simu {
    input {
        Array[File] pgen
        Array[File] psam
        Array[File] pvar
        Array[Float] admix_prop
        String build
        Int n_indiv
        Int n_gen
    }

    #Array[String] pfile = sub(pgen, "\\.pgen$", "")

    command {
        admix admix-simu \
            --pfile-list [${sep=',' pgen}] \
            --admix-prop [${sep=',' admix_prop}] \
            --n-indiv ${n_indiv} \
            --n-gen ${n_gen} \
            --build ${build} \
            --out admix
    }

    output {
        File out_pgen = "admix.pgen"
        File out_psam = "admix.psam"
        File out_pvar = "admix.pvar"
        File out_lanc = "admix.lanc"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.0"
    }
}

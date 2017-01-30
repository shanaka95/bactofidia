

SAMPLES = ["ENH-JSC-EDH-100490"]
R = ["R1","R2"]

seqtkparam = "-q 0.01  -l 30 -b 0 -e 0"
spadesparam = "--only-assembler --careful --threads 8"
spadesversion = "3.6.2"
minlen = 500
mincov = 10
krange = "57,97,127"
quastparam = "--min-contig 500"
version = "V022017"+spadesversion

prokkaparam = "--centre UMCU --compliant"
krakenparam = "--quick --db /hpc/local/CentOS7/dla_mm/tools/kraken/db/minikraken_20140330/"
checkmparam = ""

def determine_spadespath(spadesversion):
    spadespath = "/hpc/local/CentOS7/dla_mm/bin/spades.py" #standard
    if spadesversion == "3.9.0":
        spadespath = "/hpc/local/CentOS7/dla_mm/tools/miniconda2/envs/snakemake-tutorial/bin/spades.py"
    if spadesversion == "3.8.2":
        spadespath = "/hpc/local/CentOS7/dla_mm/bin/SPAdes-3.8.2-Linux/bin/spades.py"
    if spadesversion == "3.8.1":
        spadespath = "/hpc/local/CentOS7/dla_mm/tools/miniconda2/envs/spades3.8.1/bin/spades.py"
    if spadesversion == "3.8.0":  
        spadespath = "/hpc/local/CentOS7/dla_mm/bin/SPAdes-3.8.0-Linux/bin/spades.py"
    if spadesversion == "3.6.2":
        spadespath = "/hpc/local/CentOS7/dla_mm/bin/spades.py"
    if spadesversion == "3.5.0":
        spadespath = "/hpc/local/CentOS7/dla_mm/bin/SPAdes-3.5.0/spades.py"
    if spadesversion == "3.7.0":
        spadespath = "/hpc/local/CentOS7/dla_mm/bin/SPAdes-3.7.0-Linux/bin/spades.py"
    return spadespath

rule all:
    input:
       "stats/Trimmingstats.tsv",
       expand ("assembly/{sample}", sample=SAMPLES),
       expand ("scaffolds/{sample}.fna", sample=SAMPLES),
       expand ("annotation/{sample}", sample=SAMPLES),
      # expand ("{sample}", sample=SAMPLES)


rule fastqc_before:
    input:
        "data/{sample}_{r}.fastq.gz"
    output:
        temp("stats/{sample}_{r}_Trimmingstats_before_trimming")
    shell:
        "seqtk fqchk {input} | grep ALL | sed 's/ALL//g' >> {output}"

rule trim:
     input:
        "data/{sample}_{r}.fastq.gz"
     output:
        temp("trimmed/{sample}_{r}.fastq")
     params:
        seqtkparam
     shell: 
        "seqtk trimfq {params} {input} > {output}"


rule fastqc_after:
    input:
    "trimmed/{sample}_{r}.fastq"
    output:
        temp("stats/{sample}_{r}_Trimmingstats_after_trimming")
    shell:
        "seqtk fqchk {input} | grep ALL | sed 's/ALL//g' >> {output}"

rule trimstat:
    input:
       after=expand("stats/{sample}_{r}_Trimmingstats_after.tsv", sample=SAMPLES, r=R),
       before=expand("stats/{sample}_{r}_Trimmingstats_before.tsv", sample=SAMPLES, r=R)
    output:
       "stats/Trimmingstats.tsv"
    shell:
       "cat {input.before} {input.after} > {output}"
       
rule spades:
    input: 
        R1="trimmed/{sample}_R1.fastq",
        R2="trimmed/{sample}_R2.fastq"
    output:
        "assembly/{sample}"
    params:
        spadesparam = spadesparam,
        kmer = krange,
        cov = mincov,
        version = determine_spadespath(spadesversion)
    shell:
        "python {params.version} -1 {input.R1} -2 {input.R2} -o {output}  -k {params.kmer} --cov-cutoff {params.cov} {params.spadesparam}"

rule rename:
    input:
        "assembly/{sample}/scaffolds.fasta"
    output:
        "scaffolds/{sample}.fna"
    params:
        minlen = minlen,
        version = version
    shell:
        "seqtk seq -L {params.minlen} {input} | sed  s/NODE/{params.version}/g > {output}"

rule annotation:
   input:
       "scaffolds/{sample}.fna"
   output:
       outdir = "annotation/{sample}"
   params:
       prokkaparam
   shell:
       "prokka --outdir {output.outdir} {params} {input}"

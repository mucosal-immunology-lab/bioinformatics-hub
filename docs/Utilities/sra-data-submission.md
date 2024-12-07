# SRA sequencing data submission

A guide to submitting sequencing data to the National Center for Biotechnology Information (NCBI) sequencing read archive (SRA) database. Includes information on uploading data to the SRA using the high-speed Aspera Connect tool.

**Patient-derived sequencing files**

If your samples are derived from humans, ensure that your **file names include no reference to patient identifiers**. Once uploaded to the SRA database, it is very difficult to change the names of files, and requires directly contacting the database to arrange for removal of files and for you to reupload the data. It also involves a difficult process of them re-mapping the new uploads to your existing SRA metadata files.

Also ensure that you only include the absolute minimum amount of metadata, in a manner that protects patient confidentiality. Absolutely no information should be unique to one single patient in your cohort, even an age (if you have a patient with a unique age, this should be replaced with `NA` for the purposes of SRA submission). For manuscripts, you can include a phrase indicating that further metadata is available upon reasonable request. **The important thing here is to not infringe on patient privacy and confidentiality.**

Things you could potentially include:
- Modified and anonymised patient ID
- Sampling group
- Timepoint (not exact days or months)
- Sex
- Collection year (no exact dates)
- Tissue

## Process overview

1.  Register a BioProject
2.  Register BioSamples for the related BioProject
3.  Submit data to SRA

## Register a BioProject 📔

The BioProject is an important element that can link together different types of sequencing data, and represents all the sequencing data for a given experiment.

Go to the [SRA submission](https://submit.ncbi.nlm.nih.gov/) website to register a new BioProject.

- Sample scope: Multispecies (if you have microbiome data)
- Target description: Bacterial 16S metagenomics (change if you have shotgun metagenomics and/or host transcriptomics)
- Organism name: Human (change if using mouse or rat data)
- Project type: Metagenome (add transcriptome if you also have host transcriptomics)

## Register BioSamples :test_tube:

### Microbiome data 🦠

Microbiome samples will be registered as *MIMARKS Specimen* samples. On the **BioSample Attributes** tab, download the BioSample metadata Excel template, and complete it accordingly before uploading. Be very careful with the required field formats. You can double check ontology using the [EMBL-EBI Ontology Lookup Service](https://www.ebi.ac.uk/ols4/).

- Use the BioProject accession number previously generated
- **Organism**: `human metagenome` (or as appropriate)
- **Env broad scale**: `host-associated`
- **Env local scale**: `mammalia-associated habitat`
- **Env medium**: (as appropriate)
- **Strain, isolate, cultivar, ecotype**: `NA`
- Add any other relevant host information in the table, as well as the host tissue samples
- Any other column which is not relevant can be set to `NA`

The **SRA Metadata** tab is what will join everything together. Once again, download the provided Excel template, and fill everything in carefully.

- **Sample name**: the base name of your samples
- **Library ID**: you may have named your files differently than your sample names &ndash; provide this if so, otherwise you can repeat the sample name
- **Title**: a short description of the sample in the form "`{methodology}` of `{organism}`: `{sample_info}`" &ndash; e.g. "Shotgun metagenomics of Homo sapiens: childhood bronchial brushing".
- **Library strategy**: `WGS`
- **Library source**: `METAGENOMIC`
- **Library selection**: `RANDOM`
- **Library layout**: `paired`
- **Platform**: `ILLUMINA`
- **Instrument model**: `Illumina NovaSeq 6000`
- **Design description**: `NA`
- **Filetype**: `fastq`
- **Filename**: the file name of the forward reads
- **Filename2**: the file name of the reverse reads

### Transcriptomics data 👨🐭

Host transcriptomics samples will be registered as either *HUMAN* or *Model organism or animal* samples. On the **BioSample Attributes** tab, download the BioSample metadata Excel template, and complete it accordingly before uploading. Be very careful with the required field formats. You can double check ontology using the [EMBL-EBI Ontology Lookup Service](https://www.ebi.ac.uk/ols4/).

- Use the BioProject accession number previously generated
- **Organism**: `Homo sapiens` (or `Mus musculus`/`Rattus norvegicus` as appropriate)
- **Isolate**: NA
- **Age**: fill this in, but leave `NA` for human samples if it would result in a unique combination of metadata variables with potential to allow identification of any individual.
- **Biomaterial provider**: enter the lab, organisation etc. that provided the samples
- **Collection date**: do not enter any exact dates for human samples
- **Geo loc name**: country in which samples were collected
- **Sex**: provide sex of host
- **Tissue**: specify tissue origin of samples
- Add any other relevant data, such as sampling group

As above, the **SRA Metadata** tab is where the magic will happen :magic_wand::sparkles:. Once again, download the provided Excel template, and fill everything in carefully.

- **Sample name**: the base name of your samples
- **Library ID**: you may have named your files differently than your sample names &ndash; provide this if so, otherwise you can repeat the sample name
- **Title**: a short description of the sample in the form "`{methodology}` of `{organism}`: `{sample_info}`" &ndash; e.g. "RNA-Seq of Homo sapiens: childhood bronchial brushing".
- **Library strategy**: `RNA-Seq`
- **Library source**: `TRANSCRIPTOMIC`
- **Library selection**: `RANDOM`
- **Library layout**: `paired`
- **Platform**: `ILLUMINA`
- **Instrument model**: `Illumina NovaSeq 6000`
- **Design description**: `NA`
- **Filetype**: `fastq`
- **Filename**: the file name of the forward reads
- **Filename2**: the file name of the reverse reads

## Submit data to SRA 📤

!!! question "Which upload option should I choose?"

    You can choose either of the following upload options, and each has pros and cons.
    
    - **Filezilla** allows parallel uploads according to your settings, but upload speed is typically slower.
    - **Aspera Connect** (at least with NCBI) only allows sequential uploads, but the upload speed is significantly faster.

### FileZilla 🦖

Using [FileZilla](https://filezilla-project.org/) is more effective when you have large files and/or a large number of files.

In FileZilla, open the sites manager and connect to NCBI as follows:
- Protocol: `FTP`
- Host: `ftp-private.ncbi.nlm.nih.gov`
- Username: `subftp`
- Password: this is your user-specific NCBI password given when you submit your data

In the `Advanced` tab next to the `General` tab, set the `Default remote directory` field to the directory specified by NCBI. This will looks something like: `/uploads/{username}_{uniqueID}`.

Select connect, and gain access to your account folder on the NCBI FTP server.

**Create a new project folder** within the main upload folder, and enter the folder. Add your files to the upload queue, and begin the upload process.

### Aspera Connect

The IBM Aspera Connect tool allows for much faster uploads than FileZilla, and is a good alternative for large files.

#### Linux process 🐧

The process described here is for Linux, but is similar for Windows and MacOS operating systems. More information is provided on the [IBM website](https://www.ibm.com/docs/en/aspera-connect/4.2?topic=suc-installation).

1.  Download the [Aspera Connect software](https://www.ibm.com/aspera/connect/).
2.  Open a new terminal window (`Ctrl+Alt+T`)
3.  Navigate to downloads, extract the `tar.gz` file.
4.  Run the install script.

```bash
# Extract the file
tar -zxvf ibm-aspera-connect-version+platform.tar.gz
# Run the install script
./ibm-aspera-connect-version+platform.sh
```

5. Add the Aspera Connect bin folder to your PATH variable (reopen terminal to apply changes).

```bash
# Add folder to PATH
echo 'export PATH=$PATH:/home/{user}/.aspera/connect/bin/ >> ~/.bashrc'
```

6. Download the NCBI Aspera Connect [key file](https://submit.ncbi.nlm.nih.gov/preload/aspera_key/).
7. Navigate to the parent folder of the folder containing the files you want to upload to the SRA database, and create a new bash script.

```bash
# Create a new bash script file
touch upload_seq_data.sh
```

8. Add the following code to the bash script file. 
-   The `-i` argument is the path to the key file, and must be given as a full path (not a relative one).
-   The `-d` argument specifies that the directory will be created if it doesn't exist.
-   You can adjust the maximum upload speed using the `-l500m` argument, where `500` is the speed in Mbps. You could increase or decrease as desired.
-   Add the folder containing the data to upload, which can be relative to the folder containing the bash script.
-   Next provide the upload folder provided by NCBI, which will be user-specific, and **ensure you provide a project folder** at the end of this. Data will not be available if it is uploaded into the main uploads folder.

```bash title="upload_seq_data.sh"
#!/bin/bash
ascp -i {/full/path/to/key-file/aspera.openssh} -QT -l500m -k1 -d {./name-of-seq-data-folder} subasp@upload.ncbi.nlm.nih.gov:uploads/{user-specific-ID}/{name-of-project}
```

9. Run the bash script, and upload all files. The default settings will allow you to resume uploads if they are interrupted, and it will not overwrite files that are identical in the destination folder.

```bash
# Run script
bash upload_seq_data.sh
```
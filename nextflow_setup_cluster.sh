#Nextflow setup LMB Cluster
###########################

# Java setup
# Add the latest version of Java to your PATH
echo "" >> ~/.bashrc
echo "# Java" >> ~/.bashrc
echo "JAVA=$(alternatives --display java | awk '/family java-latest/ {print $1 }')" >> ~/.bashrc
echo "JAVA_HOME=${JAVA%%/bin/java}" >> ~/.bashrc
echo "export PATH=${JAVA%%/java}:$PATH" >> ~/.bashrc


# Nextflow Setup
# Add Nextflow to your PATH
echo '' >> ~/.bashrc
echo '# Nextflow' >> ~/.bashrc
echo 'export PATH="/net/nfs1/public/genomics/soft/bin:$PATH" >> ~/.bashrc' >> ~/.bashrc
source ~/.bashrc


# Run Nextflow for the first time
nextflow


# NF core setup
python3 -m pip install --user --upgrade pip
python3 -m pip install --user nf-core


# Import useful Python modules
python3 -m pip install --user numpy
python3 -m pip install --user pandas


source ~/.bashrc

#Nextflow setup LMB
###################

#Make directories if needed
if [ ! -d "$HOME/bin/" ]; then
  mkdir "$HOME/bin/"
fi

if [ ! -d "$HOME/nextflow_singularity_cache/" ]; then
  mkdir "$HOME/nextflow_singularity_cache/"
fi

#Nextflow setup
cd "$HOME/bin/"
wget -qO- https://get.nextflow.io | bash

# Nf-core setup
echo "" >> ~/.bashrc
echo "# Nextflow" >> ~/.bashrc
echo 'export NXF_SINGULARITY_CACHEDIR="$HOME/nextflow_singularity_cache/"' >> ~/.bashrc

python3 -m pip install --upgrade pip
pip3 install nf-core


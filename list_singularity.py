#!/usr/bin/env python

import nf_core.utils
from nf_core.download import DownloadWorkflow
import shutil

dl = DownloadWorkflow()
dl.prompt_pipeline_name()
dl.pipeline, dl.wf_revisions, dl.wf_branches = nf_core.utils.get_repo_releases_branches(
    dl.pipeline, dl.wfs
)
dl.prompt_revision()
dl.get_revision_hash()
dl.download_wf_files()
dl.find_container_images()
for container in dl.containers:
    print(container)
shutil.rmtree(dl.outdir)

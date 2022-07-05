#!/usr/bin/env python3

import glob
# from pathlib2 import Path

def get_file_content(filename):
    text_file = open(filename, "r")
    content = text_file.read()
    text_file.close()
    return content

def set_file_content(filename, content):
    text_file = open(filename, "wt")
    n = text_file.write(content)
    text_file.close()
    return n

# Define a known list of substitutions (for security reasons)
allowed_replacements = {
  "## template: note": "# This file is generated from template. Do not edit it.",
  "## include: cicd/_dockerfile_parts/php-composer": get_file_content("cicd/_dockerfile_parts/php-composer"),
  "## include: cicd/_dockerfile_parts/cimg-base-alpine": get_file_content("cicd/_dockerfile_parts/cimg-base-alpine"),
  "## include: cicd/_dockerfile_parts/ci-tooling-alpine": get_file_content("cicd/_dockerfile_parts/ci-tooling-alpine"),
  "## include: cicd/_dockerfile_parts/node-alpine": get_file_content("cicd/_dockerfile_parts/node-alpine"),

}

# path to search file
path = '**/Dockerfile.template'
for template in glob.glob(path, recursive=True):
    
    # requires python 3.9 
    # dockerfile = template.removesuffix('.template')
    dockerfile = template[:-len(".template")]

    print("Creating {file}".format(file=dockerfile))

    dockerfile_content = get_file_content(template)

    for k, v in allowed_replacements.items():
        dockerfile_content = dockerfile_content.replace(k, v)

    set_file_content(dockerfile, dockerfile_content)

#!/usr/bin/env python3

import os
import subprocess
import json

exclusions = ['.git', '.github']
source_images = [f.name for f in os.scandir() if f.is_dir() and f.name not in exclusions]

# destination_mappings = {
#     'cicd': 'silta-cicd', # **
#     'varnish': 'silta-varnish', # **
#     'nginx': 'silta-nginx', # *
#     'shell': 'silta-php-shell', # *
#     'openresty': 'silta-openresty', # **
#     'node': 'silta-node', # *
#     'silta-mailhog': 'silta-mailhog',
#     'php': 'silta-php-fpm', # *
#     'solr': 'silta-solr', # **
#     'silta-proxy': 'silta-proxy',
#     'rsync': 'silta-rsync', # **
# }

source_mappings = {
    'silta-cicd': 'cicd', # **
    'silta-varnish': 'varnish', # **
    'silta-nginx': 'nginx', # *
    'silta-php-shell': 'shell', # *
    'silta-openresty': 'openresty', # **
    'silta-node': 'node', # *
    'silta-mailhog': 'silta-mailhog',
    'silta-php-fpm': 'php', # *
    'silta-solr': 'solr', # **
    'silta-proxy': 'silta-proxy',
    'silta-rsync': 'rsync', # **
}

for destination_image in source_images:
    print ("#", destination_image)
    source_image = source_mappings[destination_image]
    image_tags_string = subprocess.run(['gcloud', 'container', 'images', 'list-tags', 'eu.gcr.io/silta-images/{}'.format(source_image), '--format=json'], stdout=subprocess.PIPE).stdout.decode('utf-8')
    image_tags_object = json.loads(image_tags_string)

    for digest in image_tags_object: 
        for tag in digest['tags']:
            print ("## clone 'eu.gcr.io/silta-images/{}:{}' to 'wunderio/{}:{}'".format(source_image, tag, destination_image, tag))
            
            result = subprocess.run(['docker', 'pull', 'eu.gcr.io/silta-images/{}:{}'.format(source_image, tag)], stdout=subprocess.PIPE)
            print(result.stdout.decode('utf-8'))
            
            result = subprocess.run(['docker', 'tag', 'eu.gcr.io/silta-images/{}:{}'.format(source_image, tag), 'wunderio/{}:{}'.format(destination_image, tag)], stdout=subprocess.PIPE)
            print(result.stdout.decode('utf-8'))

            result = subprocess.run(['docker', 'push', 'wunderio/{}:{}'.format(destination_image, tag)], stdout=subprocess.PIPE)
            print(result.stdout.decode('utf-8'))

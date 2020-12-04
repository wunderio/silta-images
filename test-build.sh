#!/bin/bash

function test_docker_build () {
    dockerfile=$1
    folder=${dockerfile%"/Dockerfile"}; 
    quiet=${2:-true}
    
    # Build image, tag with a random tag
    tmpName="test-image-$RANDOM"
    echo "* Building image: ${dockerfile}"
    if [ $quiet = true ]; then
        docker build $folder --file $dockerfile --quiet --tag $tmpName > /dev/null 2>&1
    else 
        docker build $folder --file $dockerfile --tag $tmpName
    fi

    if [ $? -ne 0 ]; then echo "  Build status: Failed"
    else echo "  Build status: Success"
    fi
    
    # Remove temporary build tag and image
    docker rmi $tmpName > /dev/null 2>&1
}

# No dockerfile supplied
if [ -z "$1" ]; then
    echo "Building all Dockerfiles"
    
    # List folders containing Dockerfile 
    file_list=$(find . -name "Dockerfile");
    for dockerfile in $file_list
    do test_docker_build $dockerfile
    done;
else
    test_docker_build $1 false
fi

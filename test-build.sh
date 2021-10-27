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
    else 
        echo "  Build status: Success"
        docker run -t -i --rm $tmpName bash -c "if node -v &> /dev/null; then node -v ; fi; if php -v &> /dev/null; then php -r 'echo \"PHP \" . PHP_VERSION;' ; fi;"
    fi
    
    # Remove temporary build tag and image
    docker rmi $tmpName > /dev/null 2>&1
}

# Build specific dockerfile, return full output
if [[ "$1" == *"Dockerfile"* ]]; then
    test_docker_build $1 false

# No dockerfile supplied, build all Dockerfiles, return output
else
    path=${1:-.}
    echo "Building all Dockerfiles in $path"
    
    # List folders containing Dockerfile 
    file_list=$(find $path -name "Dockerfile");
    for dockerfile in $file_list
    do test_docker_build $dockerfile
    done;
fi

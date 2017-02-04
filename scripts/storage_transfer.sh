#!/bin/bash
#script to be executed in fog
storage_host_name_with_path=10.0.0.3:/users/dycbt4/ #path to remote storage directory in cloud to store data
input_folder='../raw' #folder to store raw (unprocessed) images in fog
extension='tif'

function try()
{
    [[ $- = *e* ]]; SAVED_OPT_E=$?
    set +e
}

function throw()
{
 exit   
}

function catch()
{
    export ex_code=$?
    (( $SAVED_OPT_E )) && set +e
    return $ex_code
}

function throwErrors()
{
    set -e
}

function ignoreErrors()
{
    set +e
}

export AnException=100
export AnotherException=101
total_processing_time=0;

#transfer data to storage
scp $input_folder/*.$extension $storage_host_name_with_path #transfer file from fog to cloud storage
echo "Storage Transfer is finished";
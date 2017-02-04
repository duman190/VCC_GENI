#!/bin/bash
#script to be executed in cloud
fog_host_name_with_path=10.0.0.2:/users/dycbt4/raw #path to remote fog directory to read data
input_folder='../raw2' #folder to store raw (unprocessed) images
output_folder='../processed' #folder to store pre-processed images (which are ready for tracking)
extension='tif'
file_size=2213912 #ethalon file size (needed to estimate if file is fully transferred)

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

#prepare for cloud processing
mkdir -p $input_folder $output_folder #create folders for data storage and pre-processing
rm $input_folder/*.$extension $output_folder/*.$extension #remove all previous data in these folders (if exists)
touch $input_folder/{0000..0299}_R.$extension $output_folder/{0000..0299}_R.$extension #create dummy files 

#transfer and pre-process data (after pre-processing data are ready for tracking)
scp $fog_host_name_with_path/{0000..0299}_R.tif ../raw2 & #transfer files from fog in backgroud process
for f in {0000..0299}_R.$extension 
do 
until [ $(wc -c <"$input_folder/$f") -ge $file_size ] #wait until frame will be fully transfered
do sleep 0.05; #sleep for 50 mileseconds
done
start=`date +%s%N`; 
convert $input_folder/$f -define tiff:tile-geometry=128x128 -contrast $output_folder/$f; #pre-process frame in the cloud
end=`date +%s%N`;
echo "$f pre-processed in $(((end-start)/1000)) microseconds";
rm $input_folder/$f;
total_processing_time=$((total_processing_time+((end-start)/1000)));
done

#stop and show final pre-processing results
wait
total_processing_time=$((total_processing_time/1000));
echo "Total Pre-processing time = $total_processing_time ms"; #show final pre-processing time
#!/bin/bash
#script to be executed in fog
cloud_user_host='dycbt4@10.0.0.1' #specify user name/host needed to prepare remote cloud folders for cloud/fog processing
cloud_path='/tracking/LOFT_Lite/data/processed' #path to remote cloud directory for tracking
input_folder='../raw' #folder to read raw (unprocessed) images
output_folder='../processed' #folder to store pre-processed images (which are ready for transfer to and tracking at cloud)
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

#prepare for cloud/fog processing
mkdir -p $output_folder
ssh $cloud_user_host mkdir -p $cloud_path 
rm $output_folder/*.$extension
ssh $cloud_user_host rm $cloud_path/*.$extension
touch $output_folder/{0000..0299}_R.$extension
ssh $cloud_user_host touch $cloud_path/{0000..0299}_R.$extension

#pre-process data at fog and then transfer them to the cloud (here, we assume that pre-processing is faster than transfering)
for f in {0000..0299}_R.$extension 
do 
start=`date +%s%N`; 
convert $input_folder/$f -define tiff:tile-geometry=128x128 -contrast $output_folder/$f;
end=`date +%s%N`;
echo "$f pre-processed in $(((end-start)/1000)) microseconds"; 
total_processing_time=$((total_processing_time+((end-start)/1000)));
if [ $f == "0000_R.tif" ]
then  scp $output_folder/{0000..0299}_R.tif $cloud_user_host:$cloud_path & #transfer file from fog to cloud in backgroud process
fi
done

#wait until data transfering is done and show final pre-processing results
total_processing_time=$((total_processing_time/1000));
wait
echo "Total Pre-processing time = $total_processing_time ms";
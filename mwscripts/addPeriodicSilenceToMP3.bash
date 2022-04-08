#!/bin/bash

inputFileName=$1
silence=$2
audio=$3
ffmpeg -i $inputFileName.mp3 -ss 0 -to $silence -c copy trim$silence$inputFileName.mp3
ffmpeg -i trim$silence$inputFileName.mp3 -af volume=0:enable="'between(t,0,11)'" silentTrim$silence$inputFileName.mp3
ffmpeg -i $inputFileName.mp3 -f segment -segment_time $audio seg%05d$audio_$inputFileName.mp3
v=`ls seg*$inputFileName.mp3 | wc -l`

rm fileList.txt
for i in $(seq 1 1 $(($v-1))); 
do 
  y=$(printf "%05d" $i)
  echo "file $PWD/seg$y$audio_$inputFileName.mp3" >> fileList.txt
  echo "file $PWD/silentTrim$silence$inputFileName.mp3"  >> fileList.txt
done

ffmpeg -f concat -safe 0 -i fileList.txt -c copy a-$audio-s-$silence-$inputFileName.mp3
rm seg*$inputFileName.mp3
rm trim*$inputFileName.mp3
rm silent*$inputFileName.mp3
rm fileList.txt




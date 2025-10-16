#!/bin/bash -e
# Wait a few seconds to make sure desktop and camera services are ready
sleep 10
# Wait a few seconds for cameras to re-enumerate
sudo uhubctl -l 1 -p 1 -a off
sudo uhubctl -l 3 -p 2 -a off
sleep 1
sudo uhubctl -l 1 -p 1 -a on
sudo uhubctl -l 3 -p 2 -a on

sleep 1

cd /home/mahyar/Desktop/SD_CV_Demos
source venv/bin/activate
python parallelCV.py >> /home/mahyar/Desktop/SD_CV_Demos/camera_log.txt 2>&1


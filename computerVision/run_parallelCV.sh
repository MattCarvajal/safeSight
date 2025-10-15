#!/bin/bash -e
# Wait a few seconds to make sure desktop and camera services are ready
sleep 10
# Wait a few seconds for cameras to re-enumerate
sleep 5
cd /home/mahyar/Desktop/SD_CV_Demos
source venv/bin/activate
python parallelCV.py >> /home/mahyar/Desktop/SD_CV_Demos/camera_log.txt 2>&1


echo "*** Beginning of Testing ***"
echo "."
echo "."
echo "."

# Consumption without running any program
sudo timeout 3s .././measureGPU &> /home/nvidia/project/gpuConsumption.txt
sudo timeout 3s .././measureCPU &> /home/nvidia/project/cpuConsumption.txt
sudo timeout 3s .././measureDDR &> /home/nvidia/project/memConsumption.txt

echo -e "\n*******************" > /home/nvidia/project/gpuConsumption.txt
echo "* GPU consumption *" >> /home/nvidia/project/gpuConsumption.txt
echo "*******************" >> /home/nvidia/project/gpuConsumption.txt

echo "TESTS RESULTS" > /home/nvidia/project/summary.txt

counter=0   # Counter to select Jetson's power configuration


while (( $counter < 6 ))
do

    echo -e "\n******************" >> /home/nvidia/project/summary.txt
    echo -e "* New Power Mode *" >> /home/nvidia/project/summary.txt
    echo -e "******************" >> /home/nvidia/project/summary.txt
    if (( $counter < 5 )); then
        printf "\nJetson power configuration: $counter"
        echo -e "\nJetson power configuration: $counter" >> /home/nvidia/project/summary.txt
        printf "\n\nJetson power configuration: $counter"
        echo -e "\n\nJetson power configuration: $counter" >> /home/nvidia/project/gpuConsumption.txt
        # Set Jetson's configuration
        sudo nvpmodel -m $counter
    else
        echo -e "\nJetson power configuration: 0 + jc"
        echo -e "\nJetson power configuration: 0 + jc" >> /home/nvidia/project/summary.txt
        echo -e "\n\nJetson power configuration: 0 + jetson_clocks"
        echo -e "\n\nJetson power configuration: 0 + jetson_clocks" >> /home/nvidia/project/gpuConsumption.txt
        sudo nvpmodel -m 0
        sudo ~/jetson_clocks.sh
    fi

    sleep 1     # Let the watts stabilize
    echo -e "\n******************"
    echo "Faster R-CNN"
    echo -e "\n-While running Faster R-CNN" >> /home/nvidia/project/gpuConsumption.txt
    cd ~/project/py-faster-rcnn
    sudo timeout 40s /home/nvidia/measureGPU &>> /home/nvidia/project/gpuConsumption.txt & output=$(python tools/demo_camera.py) && fg
    fps=$(echo "$output" | tail -n1)
    # SUMMARY
    echo -e "\nFaster R-CNN - Summary" >> /home/nvidia/project/summary.txt
    printf " - FPS: " >> /home/nvidia/project/summary.txt
    echo $fps >> /home/nvidia/project/summary.txt
    echo "Faster R-CNN, $fps" >> /home/nvidia/project/summary.csv
    #echo " - Watts: " >> /home/nvidia/project/summary.txt
    ##########################
    ##########################
    ##########################


    echo -e "\n******************"
    echo "Tiny YOLO v2"
    echo -e "\n-While running Tiny YOLO v2" >> /home/nvidia/project/gpuConsumption.txt
    cd ~/project/yolov2/
    sudo timeout 30s /home/nvidia/measureGPU &>> /home/nvidia/project/gpuConsumption.txt & output=$(timeout 30s ./darknet detector demo cfg/voc.data cfg/yolov2-tiny-voc.cfg yolov2-tiny-voc.weights "nvcamerasrc ! video/x-raw(memory:NVMM), width=(int)1280, height=(int)720,format=(string)I420, framerate=(fraction)30/1 ! nvvidconv flip-method=0 ! video/x-raw, format=(string)BGRx ! videoconvert ! video/x-raw, format=(string)BGR ! appsink") && fg
    echo "$output" | grep 'FPS:' | tail -n10 > tmp.txt
    awk '{print substr($0,5,5)}' tmp.txt > tmp2.txt
    awk '{sum+=$1}END{printf "FPS=%.2f\n",sum/NR}' tmp2.txt
    fps=$(awk '{sum+=$1}END{printf "%.2f\n",sum/NR}' tmp2.txt)
    # SUMMARY
    echo -e "\nTiny YOLO v2 - Summary" >> /home/nvidia/project/summary.txt
    printf " - FPS: " >> /home/nvidia/project/summary.txt
    echo "$fps" | tail -n1 >> /home/nvidia/project/summary.txt
    ##########################
    ##########################
    ##########################


    echo -e "\n******************"
    echo "SSD"
    echo "WARNING: Read FPS values and report them yourself. The summary file will show the previously reported values."
    echo -e "\n-While running SSD" >> /home/nvidia/project/gpuConsumption.txt
    cd ~/project/ssd-caffe
    PYTHONPATH=/home/nvidia/project/ssd-caffe/python
    echo "Ready to write down the FPS? Press [ENTER]"
    read
    sudo timeout 20s /home/nvidia/measureGPU &>> /home/nvidia/project/gpuConsumption.txt & output=$(timeout 20s python ./examples/ssd/ssd_pascal_webcam.py) && fg
    # printf " - FPS: " 
    # echo $output | awk '{print $NF}'
    # SUMMARY
    echo -e "\nSSD - Summary" >> /home/nvidia/project/summary.txt
    printf " - FPS: " >> /home/nvidia/project/summary.txt
    if [ $counter -eq 0 ]; then echo "9.5" >> /home/nvidia/project/summary.txt; fi
    if [ $counter -eq 1 ]; then echo "7.9" >> /home/nvidia/project/summary.txt; fi
    if [ $counter -eq 2 ]; then echo "8.6" >> /home/nvidia/project/summary.txt; fi
    if [ $counter -eq 3 ]; then echo "9.1" >> /home/nvidia/project/summary.txt; fi
    if [ $counter -eq 4 ]; then echo "4.7" >> /home/nvidia/project/summary.txt; fi
    if [ $counter -eq 5 ]; then echo "12.9" >> /home/nvidia/project/summary.txt; fi
    echo "READ BY YOURSELF" >> /home/nvidia/project/summary.txt
    ##########################
    ##########################
    ##########################


    echo -e "\n******************"
    echo "DetectNet"
    echo -e "\n-While running DetectNet" >> /home/nvidia/project/gpuConsumption.txt
    cd ~/project
    sudo timeout 60s /home/nvidia/measureGPU &>> /home/nvidia/project/gpuConsumption.txt & output=$(timeout 60s python inferenceWithCaffe.py) && fg
    printf " - FPS: " 
    echo $output | awk '{print $NF}'
    fps=$(echo $output | awk '{print $NF}')
    # SUMMARY
    echo -e "\nDetectNet - Summary" >> /home/nvidia/project/summary.txt
    printf " - FPS: " >> /home/nvidia/project/summary.txt
    echo "$fps" >> /home/nvidia/project/summary.txt
    ##########################
    ##########################
    ##########################


    echo -e "\n******************"
    echo "DetectNet with TensorRT"
    echo -e "\n-While running DetectNet with TensorRT" >> /home/nvidia/project/gpuConsumption.txt
    cd ~/jetson-inference/build/aarch64/bin/
    #output=$(timeout 15s ./detectnet-camera coco-dog)
    sudo timeout 15s /home/nvidia/measureGPU &>> /home/nvidia/project/gpuConsumption.txt & output=$(timeout 15s ./detectnet-camera coco-dog)  && fg
    echo "$output" | grep 'FPS:' | tail -n15 > tmp.txt
    awk '{print substr($0,5,5)}' tmp.txt > tmp2.txt
    awk '{sum+=$1}END{printf "FPS=%.2f\n",sum/NR}' tmp2.txt
    fps=$(awk '{sum+=$1}END{printf "%.2f\n",sum/NR}' tmp2.txt)
    # SUMMARY
    echo -e "\nDetectNet with TensorRT - Summary" >> /home/nvidia/project/summary.txt
    printf " - FPS: " >> /home/nvidia/project/summary.txt
    echo "$fps" >> /home/nvidia/project/summary.txt
    ##########################
    ##########################
    ##########################


    echo -e "\n******************"
    echo "SSD with MobileNet"
    echo -e "\n-While running SSD with MobileNet" >> /home/nvidia/project/gpuConsumption.txt
    cd ~/project/realtime_object_detection
    sudo timeout 80s /home/nvidia/measureGPU &>> /home/nvidia/project/gpuConsumption.txt & output=$(timeout 80s python -u run_objectdetection.py) && fg
    echo "$output" | grep 'FPS:' | tail -n3 > tmp.txt
    awk '{print substr($0,8,5)}' tmp.txt > tmp2.txt
    awk '{sum+=$1}END{printf "FPS=%.2f\n",sum/NR}' tmp2.txt
    fps=$(awk '{sum+=$1}END{printf "%.2f\n",sum/NR}' tmp2.txt)
    # SUMMARY
    echo -e "\nSSD with MobileNet - Summary" >> /home/nvidia/project/summary.txt
    printf " - FPS: " >> /home/nvidia/project/summary.txt
    echo "$fps" | tail -n1 >> /home/nvidia/project/summary.txt
    ##########################
    ##########################
    ##########################

    ((counter++))
done


cd /home/nvidia/project
python createTable.py

echo "."
echo "."
echo "."
echo "******************"
echo "Testing finished. Table created in the project directory: \"finalTable.csv\""
echo "Time elapsed:"

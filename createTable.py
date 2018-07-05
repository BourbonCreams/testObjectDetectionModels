import csv


finalWatts = []

baseFlag = False

# Extract GPU consumption to be reported
with open("gpuConsumption.txt") as f:

    line = f.readline()
    while line:
    
        if line[:7] == "-Before":
            baseFlag = True
            
        if line[:3] == "GPU":
            watts = float(line.split()[2])
            maxWatts = watts
            minWatts = watts

            while True:
                if maxWatts < watts:
                    maxWatts = watts

                if minWatts > watts:
                    minWatts = watts

                # Read next line
                line = f.readline()
                if len(line) > 5 and line[:3] == "GPU":
                    watts = float(line.split()[2])
                else:

                    if baseFlag == True:
                        finalWatts.append("Base")
                        finalWatts.append(minWatts)
                        baseFlag = False
                    else:
                        finalWatts.append(maxWatts)

                    break
        else:
            line = f.readline()


finalFPS = []

# Extract FPS values to be reported
with open("summary.txt") as f:
    line = f.readline()
    while line:
        
        if line[:12] == "Jetson power":
            finalFPS.append("\n")
          #  finalFPS.append(line[28:-1])
            
        if "Faster R-CNN" in line or "Tiny YOLO v2" in line or "SSD" in line or "DetectNet" in line:
            line = f.readline()
            fps = line.split()[2]
            finalFPS.append(fps)
            #finalFPS.append(",")
            
            
        line = f.readline()


# Create .csv file
counter = 0
header = ["", "Faster R-CNN", "", "", "Tiny YOLO v2", "", "", "SSD", "", "", "DetectNet", "", "", "DetectNet+Trt", "", "", "SSD+MobileNet", "", "",]
header2 = ["", "FPS", "Watts", "Efficiency", "FPS", "Watts", "Efficiency", "FPS", "Watts", "Efficiency", "FPS", "Watts", "Efficiency", "FPS", "Watts", "Efficiency", "FPS", "Watts", "Efficiency"]


with open("finalTable.csv", "wb") as f:
    wr = csv.writer(f, quoting=csv.QUOTE_ALL)
    wr.writerow(header)
    wr.writerow(header2)
    newRow = []
    elemCounter = 0
    for elem in finalFPS:
        if elem != "\n":
            watts = finalWatts[elemCounter]/1000        # Convert milliWatts to Watts
            newRow.append(elem)
            newRow.append("%.2f" % watts)
            newRow.append("%.2f" % (float(elem)/watts))
            elemCounter += 1
        elif len(newRow) > 0:
            newRow = [str(counter)] + newRow
            wr.writerow(newRow)
            newRow = []
            if counter < 4:
                counter += 1
            else:
                counter = "0+jc"
    wr.writerow([str(counter)] + newRow)

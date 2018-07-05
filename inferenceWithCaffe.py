import sys
import caffe
import cv2
import numpy as np
import time
import glob

modelName = "detectnet"
if modelName == "detectnet":
    imgSize = 640
elif modelName == "ssd":
    imgSize = 300
else:
    print "Entering a new model? Image size? Define it before going on."
    sys.exit(0)

imgs = [np.resize(cv2.imread(file),(imgSize,imgSize,3)).reshape(1,imgSize,imgSize,3).transpose(0,3,1,2) for file in glob.glob("test_images/*")]
print len(imgs)


caffe.set_device(0)
caffe.set_mode_gpu()

if modelName == "ssd":
    model = "/home/nvidia/project/ssd-caffe/models/VGGNet/VOC0712/SSD_300x300/deploy.prototxt"
    weights = "/home/nvidia/project/ssd-caffe/models/VGGNet/VOC0712/SSD_300x300/VGG_VOC0712_SSD_300x300_iter_120000.caffemodel"
    for img in imgs:
        img = np.resize(img,(300,300,3)).reshape(1,300,300,3).transpose(0,3,1,2)

elif modelName == "fasterrcnn":
    model = "/home/nvidia/project/py-faster-rcnn/models/coco/VGG16/faster_rcnn_end2end/test.prototxt"
    weights = "/home/nvidia/project/py-faster-rcnn/data/faster_rcnn_models/VGG16_faster_rcnn_final.caffemodel"
    
elif modelName == "detectnet":
    model = "/home/nvidia/jetson-inference/data/networks/DetectNet-COCO-Dog/deploy.prototxt"
    weights = "/home/nvidia/jetson-inference/data/networks/DetectNet-COCO-Dog/snapshot_iter_38600.caffemodel"


elif modelName == "upgradeddetectnet":
    model = "/home/nvidia/project/ssd-caffe/upgradedModels/deploy.prototxt"
    weights = "/home/nvidia/jetson-inference/data/networks/DetectNet-COCO-Dog/snapshot_iter_38600.caffemodel"
    nimga = np.resize(nimga,(256,256,3))
    nimgb = np.resize(nimgb,(256,256,3))


print "\n*** Loading model ***"
time.sleep(10)
net = caffe.Net(model, weights, caffe.TEST)

print "\n*** Info ***"
time.sleep(1)
for k, v in net.blobs.items():
    print k, v.data.shape

#print nimga.shape
#print nimgb.shape

print "\n*** Inference ***"
time.sleep(1)
start = time.time()

counter = 1
for img in imgs:
    net.forward_all(**{"data":img})
    print counter
    counter += 1

inferenceTime = time.time()-start
print "Elapsed time:", inferenceTime
print "FPS: %.2f" % (1/(inferenceTime/len(imgs)))

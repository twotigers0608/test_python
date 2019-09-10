from PIL import Image
import numpy as np
import sys
#import matplotlib.pyplot as plt
img=np.array(Image.open(sys.argv[1]).convert('L'))
#print img

rows,cols=img.shape
low=0
high=0
for i in range(rows):
    for j in range(cols):
        if (img[i,j]<=128):
            img[i,j]=0
            low=low+1
        else:
            img[i,j]=1
            high=high+1
white_present=(low / (high + low)) * 100
print ("Present of white: ", white_present)
if white_present >= 2 and white_present <= 98:
    print ("Picture color is normal")
    sys.exit(0)
elif white_present == 0 or white_present == 100:
    print ("Picture color is abnormal\n")
    print ("Picture shows pure color, it maybe white, black or any other pure color")
    print ("No camera failed to get photos")
    sys.exit(1)
else:
    print ("Picture color is abnormal\n")
    print ("Picture shows too white or too black color")
    sys.exit(1)

# -*- coding:utf-8 -*-
import os
import numpy as np
import cv2
import sys
import time
from PIL import Image

mp4_pash = os.getcwd()
os.path.join(mp4_pash)


def captrue_time(video_name):
    cap = cv2.VideoCapture(video_name)
    # video frame rate
    fps = cap.get(cv2.CAP_PROP_FPS)
    # video total frame size
    frameCount = cap.get(cv2.CAP_PROP_FRAME_COUNT)
    print('fps:' + str(fps), 'frame_count:' + str(frameCount))
    images = './results/image/'
    if not os.path.exists(images):
        os.mkdir(images)
    success, frame = cap.read()
    timeF = 25
    c = 1
    while success:
        success, frame = cap.read()
        if (c % timeF == 0):
            cv2.imwrite(images + str(c) + '.jpg', frame)
        c = c + 1
        # cv2.waitkey(1)
    cap.release()


def check_mp4pic():
    # gets the value of each frame
    v_pic = os.walk('results/image', topdown=False)
    result_dict = {'successful': [], 'fail': []}
    for name, dir, files in v_pic:
        print('file length', len(list(files)))
        for file in files:
            img = np.array(Image.open(name + '/' + file).convert('L'))
            # print img
            rows, cols = img.shape
            low = 0
            high = 0
            for i in range(rows):
                for j in range(cols):
                    if img[i, j] <= 128:
                        img[i, j] = 0
                        low += 1
                    else:
                        img[i, j] = 1
                        high += 1
            white_present = (low / (high + low)) * 100

            if white_present == 0 or white_present == 100:
                result_dict['fail'].append(file)
            elif 2 < white_present < 98:
                result_dict['successful'].append(file)
            else:
                result_dict['fail'].append(file)
    #output result
    s_result = len(result_dict['successful'])
    f_result = len(result_dict['fail'])
    print(result_dict)
    try:
        result = s_result / (s_result + f_result) * 100
        print('present successful:', result)
        if result >= 99:
            print('video is normal')
            sys.exit(0)
        else:
            print('video is failed')
            sys.exit(1)

    except Exception as e:
        print(e)
        print('test fail')
        print('video shows pure color, it maybe white, black or any other pure color')
        sys.exit(1)


if __name__ == '__main__':
    video_name = sys.argv[1]
    captrue_time(video_name)
    check_mp4pic()

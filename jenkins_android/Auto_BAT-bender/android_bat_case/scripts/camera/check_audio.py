# -*- coding:utf-8 -*-
from moviepy.editor import *
import sys
import wave as we
import numpy as np

SUCCESS = 0
FAIL = 1


def check_audio(path):
    wavfile = we.open(path, "rb")
    params = wavfile.getparams()
    framesra, frameswav = params[2], params[3]
    datawav = wavfile.readframes(frameswav)
    wavfile.close()
    datause = np.fromstring(datawav, dtype=np.short)
    abs = np.average(np.abs(datause))
    print(abs)
    if abs < 20:
        print('voido failed')
        sys.exit(1)

    else:
        print('voiced')
        sys.exit(0)


if __name__ == "__main__":
    filename = sys.argv[1]
    video = VideoFileClip(filename)
    audio = video.audio
    audio.write_audiofile('test.wav')
    check_audio('test.wav')

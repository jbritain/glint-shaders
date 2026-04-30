import os

os.environ["OPENCV_IO_ENABLE_OPENEXR"] = "1"
import cv2
import numpy as np


starmap = cv2.imread("starmap_2020_4k.exr", cv2.IMREAD_ANYCOLOR | cv2.IMREAD_ANYDEPTH)

starmap = cv2.cvtColor(starmap, cv2.COLOR_BGR2RGB)

starmap = starmap.astype(np.float16)
starmap = np.ascontiguousarray(starmap)
with open("starmap.bin", "wb") as f:
    f.write(starmap.tobytes())

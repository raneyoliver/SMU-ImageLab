# Flipped Module 3 - Oliver Raney

Team Members: Oliver Raney

For thought:
1. Given that each float array is 100 points: how many milliseconds of data has been collected? Please describe your
method for deriving this time span.

  Since the video is 30 FPS, there are 30 readings per second. This would take 3.33 seconds to read 100 times (3,333 milliseconds). If you count each RGB channel separately, then 3x30 readings are taken per second while only adding 30 to the float array. Then in the same 3.33 seconds, 9,999 milliseconds of data is collected.

2. Does this project correctly adhere to the paradigm of Model View Controller? Why or why not?

  For the most part, yes. Most of the logic is in the OpenCVBridge.mm file, and the ViewController is used to setup this class as well as implement functionality to UI buttons, and also instantiates OpenCV face detection (without implementing its logic there).

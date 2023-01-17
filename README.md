# A short set of functions to extract color values from a video

The intended use is to derive information about a filmed animal's heartbeat (hence the name) in taxa where it can be seen by transparency, naturally or by shining a light source through: select the heart/ a representative area with visible beat, then get back variation in the color of that ROI through time.  

Color values through time for each RGB channel are then exported as `csv` files (if the video is grayscale, the same info will be pasted in the three channel columns)

The second intended use is as a practical exercise to learn Julia from scratch. As a result, code may be messy and non-standard (but functional!)

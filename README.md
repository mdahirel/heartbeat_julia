# A short set of functions to extract color values from a video

The intended use is to derive information about a filmed and immobile animal's heartbeat (hence the name) in taxa where it can be seen by transparency, naturally or by shining a light source through. It can easily be repurposed for any scenario where we want to know the average colour of a manually selected region of interest through time, obviously.

Executing the code makes you go through the following steps:

- choose and import an `mp4` video
- based on the first few seconds of the video, select manually through a GUI the heart/ a representative area with visible beat through a GUI
- estimate : estimate variation in the colour of that ROI through time for the whole video
- check the quality of the results via plots
- export as `csv` if good enough, redo ROI selection if not

Color values through time are collected for each RGB channel; if the video is grayscale, the same info will be pasted in the three channel columns.

The second intended use is as a practical exercise while I am learning Julia from scratch. As a result, code may be messy and non-standard (but functional!)

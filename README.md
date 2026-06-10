## Nuceli analizer macro developed by Arnau Ortega
This macro was developed for use with FIJI distribution of ImageJ 1.54p using images taken using a Nikon eclipse TE2000-U connected with a Nikon digital sight system controlled with NIS-Elements F4.00.06 software.
# Use instructions:
1. Images must be organized in nested folders where the first level contains the sample and the second level contains the marker used (eg. "Directory/Sample/Marker/")
2. Images need to be organized by channels where for any given image channels need to be next to each other
3.a Change macro settings on the pop-up window
     Directory: Main directory containing the nested folders
     Number of channels: Number of channels for each image
     DAPI channel number: Position of the DAPI channel
     Marker channel number: Position of the marker channel
     Min/Max size: Minimum and maximum size of nuclei to be mesured
     Detect foci: Perform foci detection and counting
     Advanced options:
       Make new masks: Make new masks (if false existing ROI selections must be provided in "Directory/00-Results/ROIs/" with the naming scheme "MarkerSample.zip"
       Make new readings: Make new mesurements of nuclear intensity or foci count
       Remove scalebar: Removes bottom right corner to eliminate scalebars
       Debug mode: Will stop during the process of mask creation and nuclear analisis to show results.
3.b Find maxima settings (only if mesuring foci)
  Noise tolerance: Noise threshold (adjust depending on the data)
  Output type: How will maxima will be represented in the mask (Single points is recomended)
  Exclude Edge maxima: ignores maxima on image edges
  Light background: Does the image have a light backgound
4. Results are outputted on the "Directory/00-Results/Data/" directory as cvs files with the "MarkerSample.cvs" naming scheme

Example data is provided in the correct imput format in the Data.zip file
   

//Settings
Dialog.create("Enter data main directory");
Dialog.addDirectory("Directory","");
Dialog.addChoice("Nuber of channels", newArray("1","2","3"),"2");
Dialog.addChoice("DAPI channel number", newArray("1","2","3"),"1");
Dialog.addChoice("Marker channel number", newArray("1","2","3"),"2");
Dialog.addNumber("Min size", 1000)
Dialog.addNumber("Max size", 10000)
Dialog.addCheckbox("Detect foci", true);
Dialog.addMessage("Advanced Options:")
Dialog.addCheckbox("Make new masks", true);
Dialog.addCheckbox("Make new readings", true);
Dialog.addCheckbox("Remove scalebar", false);
Dialog.addCheckbox("Debug mode", false);
Dialog.show();
//reading user input
maindir= Dialog.getString();
c=Dialog.getChoice();
b=Dialog.getChoice();
g=Dialog.getChoice();
min=Dialog.getNumber();
max=Dialog.getNumber();
foci=Dialog.getCheckbox();
masking=Dialog.getCheckbox();
reading=Dialog.getCheckbox();
scalebar=Dialog.getCheckbox();
testing=Dialog.getCheckbox();
var DAPI = 0;
//get findStackMaxima options if foci are to be counted
if(foci){
  Dialog.create("Find Maxima");
  Dialog.addNumber("Noise Tolerance:", 8);
  Dialog.addChoice("Output Type:", newArray("Single Points", "Maxima Within Tolerance", "Segmented Particles", "Count"));
  Dialog.addCheckbox("Exclude Edge Maxima", false);
  Dialog.addCheckbox("Light Background", false);
  Dialog.show();
  tolerance = Dialog.getNumber();
  type = Dialog.getChoice();
  exclude = Dialog.getCheckbox();
  light = Dialog.getCheckbox();
  options = "";
  if (exclude) options = options + " exclude";
  if (light) options = options + " light";
}
//making output directory if not available
outdir=maindir+"00-Results/";
if (!File.exists(outdir)) {
	File.makeDirectory(outdir);
	File.makeDirectory(outdir+"ROIs");
	File.makeDirectory(outdir+"Masks");
	File.makeDirectory(outdir+"Data");
}
//looping for all samples and conditions
samples = Array.copy(Array.sort(getFileList(maindir)));
//data adquisition loop
count=0;
for(i=1; i<samples.length;i++){ //i=2 pq els i=1 estan marcats "a ma"
	if (endsWith(samples[i], "/")){
		sample=substring(samples[i],0,lengthOf(samples[i])-1);
		markers = getFileList(maindir+samples[i]);
		for (j=0; j<markers.length;j++) {
			if (endsWith(markers[j], "/")){
				marker=substring(markers[j],0,lengthOf(markers[j])-1);
				dir=maindir+samples[i]+markers[j];
				pics= Array.copy(Array.sort(getFileList(dir)));
				if (lengthOf(pics)>1) {
					if (masking){
						count=count+1;
						findnuclei(dir);
						}
					if(reading){
						analizenuclei(dir);
						}
					}
			}
		}
	}
}




function findnuclei(dir){ //nuclei finder from DAPI image
    File.openSequence(dir, " bitdepth=8 start=" + b + " step=" + c); //open DAPI stainings

    if(testing){
    	DAPI=getImageID();
    	rename("DAPI");
    	run("Duplicate...", "duplicate");
    	Mask=getImageID();
    	selectImage(Mask);
    }
    rename("Mask");
    run("Make Binary", "method=MaxEntropy calculate black"); //thresholding DAPI stainings to create mask
   if(scalebar){
    //remove scale bar
    makeRectangle(1340, 1065, 240, 55);
    setBackgroundColor(0, 0, 0);
    run("Clear", "stack");
    run("Select None");
    }

    //mask processing
    for (k = 0; k < 3; k++) {
      run("Open", "stack");
      run("Erode", "stack");
    	}

   	run("Watershed", "stack"); //separate joined nuclei

   	run("Analyze Particles...", "size="+min+"-"+max+" exclude clear add stack"); //select masked nuclei as Regions Of Interest (ROI)
  	if(testing){
  	selectImage(DAPI);
  	roiManager("Show All"); //Display ROI
    waitForUser("Check ROIs before proceeding "+sample+ " " + count+"/8");
  	selectImage(Mask);
  	}
    roiManager("Save", outdir+"/ROIs/"+marker+sample+".zip"); //Save ROIs
    save(outdir+"/Masks/"+marker+sample+"tif"); //Save masked image
    if(testing&&foci){
    	selectImage(Mask);
    	run("Close");
    }
    else {
    close("*");
    }
    roiManager("Delete");
}
function analizenuclei(dir){
    roiManager("Open", outdir+"/ROIs/"+marker+sample+".zip");
    File.openSequence(dir, " bitdepth=8 start=" + g + " step=" + c);
    rename("Signal");
    input="Signal";
    roiManager("Show All");
    run("Set Measurements...", "area mean min redirect=None decimal=3");
	if(testing&&!foci){
   	waitForUser("Check ROIs before proceeding " + sample + marker);
   	}
	roiManager("Measure");
	saveAs("Results", outdir+"Data/"+marker+sample+".csv");
	run("Clear Results");
	if(foci){
		focicounter();
		}
	close("*");
	roiManager("Deselect");
	roiManager("Delete");
    }
function focicounter(){
	findStackMaxima(); //generate foci mask
//foci processing
	for (k = 0; k < 4; k++) {
      run("Dilate", "stack");
    	}
  	run("Watershed","stack");
	if(testing){
		original= getImageID();
		run("Duplicate...", "duplicate");
		rename("foci");
		selectImage(input);
		setMinAndMax(0, 25);
		if (masking){
			selectImage(DAPI);
		}
		else {
			File.openSequence(dir, " bitdepth=8 start=" + b + " step=" + c);  //open DAPI stainings
		}
    	rename("DAPI");
    	setMinAndMax(65, 160);
	//generate composite with channels
		run("Merge Channels...", "c1=foci c2="+input+" c3=DAPI create keep");
		comp=getImageID();
		run("Channels Tool...");
		waitForUser("Check channel processing"); //Manual revison of results
	//generate RGB with ROIs drawn
		run("Apply LUT", "stack");
		selectImage(comp);
		run("RGB Color", "slices");
		roiManager("draw");
		roiManager("Show All");
   		waitForUser("Check Masks before proceeding " + sample + marker); //showing RGBs
   		selectImage(original);
   	}
   	
	n=roiManager("Count");
	for (i=0;i<n;i++){ //iterate for all nuclei
		roiManager("Select", i);
		run("Analyze Particles...", "exclude summarize slice"); //count foci in nuclei
		roiManager("Select", i);
		run("Clear", "slice"); //delete foci in selection to avoid duplicate counting on overlaping nuclei
	}
	saveAs("Results", outdir+"Data/"+marker+sample+"foci.csv");
	run("Close");

}


function findStackMaxima(){ //find maxima iterated trough a stack
  setBatchMode(true);
  n = nSlices();
  for (i=1; i<=n; i++) {
     showProgress(i, n);
     selectImage(input);
     setSlice(i);
     run("Find Maxima...", "noise="+ tolerance +" output=["+type+"]"+options);
     if (i==1)
        output = getImageID();
    else if (type!="Count") {
       run("Select All");
       run("Copy");
       close();
       selectImage(output);
       run("Add Slice");
       run("Paste");

    }
    setMetadata("Label", i);
  }
  run("Select None");
  setBatchMode(false);
}

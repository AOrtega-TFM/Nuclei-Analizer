//Settings
Dialog.create("Enter data main directory");
Dialog.addDirectory("Directory","G:/La meva unitat/Master/TFM/Resultats/Media change/2n intent/Media change/Plate/");
Dialog.addChoice("Nuber of channels", newArray("1","2","3"),"2");
Dialog.addChoice("DAPI channel number", newArray("1","2","3"),"1");
Dialog.addChoice("Marker channel number", newArray("1","2","3"),"2");
Dialog.addNumber("Min size", 1000)
Dialog.addNumber("Max size", 10000)
Dialog.addCheckbox("Detect foci", true);
Dialog.addMessage("Advanced Options:")
Dialog.addCheckbox("Make new masks", false);
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
//making output directory if not available
outdir=maindir+"00-Results/"
if (!File.exists(outdir)) {
	File.makeDirectory(outdir);
	File.makeDirectory(outdir+"ROIs");
	File.makeDirectory(outdir+"Masks");
	File.makeDirectory(outdir+"Data");
}
//looping for all samples and conditions
samples = Array.copy(Array.sort(getFileList(maindir)));
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
    	}
   	
   	run("Watershed", "stack"); //separate joined nuclei
   	if(testing){
   	waitForUser("Check Masks before proceeding " + sample + marker);
   	}
    
   	run("Analyze Particles...", "size="+min+"-"+max+" exclude clear add stack"); //select masked nuclei as Regions Of Interest (ROI)
  	if(testing){
  	File.openSequence(dir, "start=" + b + " step=" + c);
  	rename("original");
  	roiManager("Show All"); //Display ROI
    waitForUser("Check ROIs before proceeding " + ((j+1)*i)+"/"+(samples.length*markers.length));
  	}
    roiManager("Save", outdir+"/ROIs/"+marker+sample+".zip"); //Save ROIs
    save(outdir+"/Masks/"+marker+sample+"tif"); //Save masked image
    close("*");
    roiManager("Delete");
}
function analizenuclei(dir){    
    roiManager("Open", outdir+"/ROIs/"+marker+sample+".zip");
    File.openSequence(dir, " bitdepth=8 start=" + g + " step=" + c);
    roiManager("Show All")
    run("Set Measurements...", "area mean min redirect=None decimal=3");
	if(testing){
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
	run("Top Hat...", "radius=2 stack");
	run("Make Binary", "method=Triangle calculate black");
	run("Watershed", "stack");
	if(testing){
   	waitForUser("Check Masks before proceeding " + sample + marker);
   	}
	n=roiManager("Count");
	for (i=0;i<n;i++){
	roiManager("Select", i);
	run("Analyze Particles...", "exclude summarize slice");
	}
	saveAs("Results", outdir+"Data/"+marker+sample+"foci.csv");
	run("Close");

}


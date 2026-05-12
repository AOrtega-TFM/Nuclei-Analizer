s=getSliceNumber()
n=roiManager("Count");
RoiManager.selectPosition(0, 1, 0);
indexes=split(call("ij.plugin.frame.RoiManager.getIndexesAsString"));
roiManager("select", indexes);
roiManager("translate", -100, 0);

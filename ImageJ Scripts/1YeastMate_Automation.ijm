Dialog.create("Important");
Dialog.addMessage("Choose cell images directory:");
Dialog.show();
cell_dir = getDirectory("Choose cell images directory:");
cell_list = getFileList(cell_dir);
mask_directory = cell_dir + "Cells Masks";
File.makeDirectory(mask_directory);

waitForUser("Are the YeastMate Backends open? If not, open before continuing.");
//Go over images in folder
for (img = 0; img < cell_list.length; img++) {
	cell_img_path = cell_dir + cell_list[img];
	if (File.isFile(cell_img_path)) {
		img_path = cell_dir + cell_list[img];
		open(img_path);
		slices_num = nSlices;
		og_slices_num = nSlices;
		//Go over each slice in an image
		for (slice = 0; slice < slices_num; slice++) {
			selectWindow(cell_list[img]);
			setSlice(slice + 1);
			run("YeastMate", "scorethresholdsingle=0.6 scorethresholdmating=0.75 scorethresholdbudding=0.75 minnormalizationqualtile=0.015 maxnormalizationqualtile=0.985 addsinglerois=false addmatingrois=false addbuddingrois=false showsegmentation=true onlyselectedclassesinmask=false processeveryframe=false mintrackingoverlap=0.25 ipadress=localhost:11005");
		}
		//Convert to mask image
		run("Images to Stack", "  title=seg use");
		stacked_mask = getTitle();
		setThreshold(0, 1);
		run("Convert to Mask", "method=Default background=Dark black");
		//Find slice with max amount of cells
		max_cell_num = 0;
		max_slice = 0;
		slices_num = nSlices;
		for (slice = 0; slice < slices_num; slice++) {
			selectWindow(stacked_mask);
			setSlice(slice + 1);
			if (isOpen("ROI Manager")) {
				roiManager("reset");
			}
			run("Analyze Particles...", "add slice");
			if (roiManager("count") > max_cell_num) {
				max_cell_num = roiManager("count");
				max_slice = slice;
			}
		}
		//Duplicate max slice and create stack image of it
		selectWindow(stacked_mask);
		setSlice(max_slice + 1);
		run("Duplicate...", "title=[Max Slice]");
		run("Convert to Mask");
		
		for (slice = 0; slice < (og_slices_num - 1); slice++) {
			run("Duplicate...", " ");
		}
		run("Images to Stack", "  title=Max use");
		saveAs("tiff", mask_directory + File.separator + cell_list[img] + "Mask");
		run("Close All");
		close("Roi Manager");
	}
}
//TODO: 1) 
/////// 2) 
/////// 3) 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#############################
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////Global variable construction & assignment
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#############################
var firstRun = true;										//this is a boolean to indicate whether this is the first run or not. Will be set to true during the first main loop
var currentImage = 0;										//the currentImg is the image number that we are on in the directory; this is used to keep up the with the list of images and open images sequentially
var minThreshold = 15;var maxThreshold = 255;				//the minThreshold and maxThreshold are later user-defined if manualThreshold is enabled and are used for the threshold functionality
var minParticleSize = 100;var maxParticleSize = 10000;		//the minParticleSize,maxParticleSize and minCircularity,maxCircularrity are later user-defined and are used in the analyze particles function
var minCircularity = 0.01;var maxCircularity = 1.00;		//the minParticleSize,maxParticleSize and minCircularity,maxCircularrity are later user-defined and are used in the analyze particles function
var thresholdOpen = false;									//used to keep track of whether or not the threshold dialog box is opened
var batch = true;											//the batch boolean is used to indicate whether we should run through all images in the current directory or just the image opened by the user
var manualThreshold = true;var manualSelection = true;		//manualThreshold allows for manual thresholds to be applied by the user or for an automated threshold to be defined by the user
var watershed = true;var dilate = false;					//allow user to decide whether or not watershed or dilate should be applied to the ROI masks
var maskingChannel = "";									//leave this string blank as it will be set later. This string is also used like a boolean in the sense that an if statement is ran if it isn't true and if it is then else is ran.
var queryChannel = "";										//leave this string blank as it will be set later. This string is also used like a boolean in the sense that an if statement is ran if it isn't true and if it is then else is ran.
var resultsSaveName = "_results.csv";						//this will be the suffix attached to the saved .csv results.
var resultsSaveDir = "/Excel.csvs/";						//this will be the subdirectory that the .csvs are saved to. I.e. the subdirectory will be "*/.csvs/" if this is "/.csvs/"
var roiSaveDir = "/ROI.zips/";								//this will be the subdirectory that the ROIs are saved to. Same as the resultsSaveDir
var backgroundROISuffix = "_Background_Selection_ROI.zip";	//this will be used as the suffix for the background selection ROI
var queryROISuffix = "_Query_Mask_ROIs.zip";				//this will be used as the suffix for the query mask selection ROI
var measurementROISuffix = "_Measurement_ROIs.zip";			//this will be used as the suffix for the measurement selection ROI(includes query and background)
var maskingName = "";										//this will be used to store and select the masking window name
var roiBGArea = "";											//this will be used to store and retrieve the background/ selection area ROI
var roiQueryArea = "";										//this will be used to store and retrieve the query/ measurement area ROI
var images;													//the images in our working directory which will be declared as a list later.
var backgroundSignal = 0;									//this will be set each image to keep track of the background measurement
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#############################
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////Start of the main code block
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#############################
waitForUser("Welcome to AIABS. Please ensure that the ROI Manager and other images are closed before continuing.");								//give the user a heads up to close all windows
waitForUser("Please ensure all images are in the same folder with no other files. Next you will be prompted to open the first image.");								//give the user a heads up that they should open the first image in the directory
open();																							//ask user to open an image
requestSettings();																				//requestSettings() function will open up a dialog to get all the user-defined settings
var dir = getDirectory("image");																//store the current directory
var list = getFileList(dir);																	//store the list of files in the directory
var saveDir = dir + "/results/";																//this is the directory we will use to save all the results, and rois
if(File.exists(saveDir) == false) File.makeDirectory(saveDir);									//if the save directory doesn't exist then we need to make it
if(File.exists(saveDir+roiSaveDir) == false)File.makeDirectory(saveDir+roiSaveDir);				//if the save ROI directory doesn't exist then we need to make it
if(File.exists(saveDir+resultsSaveDir) == false)File.makeDirectory(saveDir+resultsSaveDir);		//if the save Results directory doesn't exist then we need to make it
var originalFileName = File.name;																//store the filename of the currently opened image (the original image)
var originalFilePath = dir+originalFileName;													//store the file path of the currently opened image (the original image)
initializeImage();																				//initializeImage will split the RGB stack into individual RGB channels and set the selection tool before calling waitForSelection. This will iniitate a cycle that progresses until it hits an error or the user terminates the macro.
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#############################
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////Start of the main program loop
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#############################
function initializeImage()
{		
		imageInfo = getImageInfo();//assign the imageInfo variable to the current image's info using the getImageInfo() function
		if(indexOf(imageInfo, "RGB") > 0 )//if the image is an RGB stack
		{run("Split Channels");}//convert the stack to images/split the channels
		else{run("Stack to Images");}//else if the image is a hyperstak then unstack
		setTool("polygon");//set the current tool to polygon
		focusMaskingChannel();//Continue forward and set the focus to the masking channel
}
////
function focusMaskingChannel()
{
	if(maskingChannel == "")//if the masking channel is not yet saved then bring up the dialog to select the masking channel color
	{
		images = getList("image.titles");
		Dialog.create("Select the masking channel");
		Dialog.addChoice("Current images",images);//a dialog box with a dropdown menu of all current images
		Dialog.show();
		maskingWindow = Dialog.getChoice();
		//This is a  way of getting the color of the window that we are on and then setting a suffix that
		//will allow us to later get the name of a window based on the channel we want to use plus the name of the 
		//last opened file. This string based method could probably be replaced with a struct type or enum.
			if(indexOf(maskingWindow, "blue") != -1)//if the selected channel was the blue channel
				{
				maskingChannel = " (blue)";//this is the suffix imagej gives to the blue channel
				}
			if(indexOf(maskingWindow, "red") != -1)//if the selected channel was the red channel
				{
				maskingChannel = " (red)";//this is the suffix imagej gives to the red channel
				}
			if(indexOf(maskingWindow, "green") != -1)//if the selected channel was the green channel
				{
				maskingChannel = " (green)";//this is the suffix imagej gives to the green channel
				}
	}
	showWindows();
	maskingName = File.name + maskingChannel;
	selectWindow(maskingName);
	//store for overlay use later
	run("Select All");
	run("Copy to System");
	run("System Clipboard");
	rename(maskingName + " analysis");
	wait(1000);// wait 1 sec
	selectWindow(maskingName);
	hideWindows();//hide the images for greater performance
	waitForSelection();//Continue forward and start the loop that will wait until there is a selection
	//the waitForSelection() function will then call the maskThreshold() function
}
////
 function waitForSelection()
 {
 	//create and assign the strings to retreive the roi save files from the rois directory
 	roiBGArea = saveDir + roiSaveDir + File.name + backgroundROISuffix;
 	roiStaticNameArea = saveDir + roiSaveDir + backgroundROISuffix;
	showWindows();//if we are in the automated mode then show the windows
 	if(manualSelection)
 		{//if we are in the manual selection mode then allow the user to select a working area
 	run("Select None");
 	waitForUser("Please use the selection tool to select an area which encompasses all of the areas that should be included in the measurements. Then press OK to continue.");
 	 //snapback to same function if no selection this loop can continue on forever if no selection is ever made
		if(selectionType() < 0)
		{
			waitForSelection();
			return;
		}
		//clear all the area outside the selected area for the masking channel
		run("Clear Outside");
		//add this area which will later be defined at the "selectionArea" or "totalROI"
		roiManager("add");
		//select the last created ROI which will be the total selection area
		roiManager("Select", 0);
		//rename the ROI as total selected area
		//store the selection area as a ROI to subtract background later
		roiManager("save", roiBGArea)
 		}else//if we aren't in manual selection mode just ask for the selection 
	 		{
	 		if(firstRun)
	 			{// only ask for this area once
		 			run("Select None");
		 			waitForUser("Please use the selection tool to select an area which encompasses all of the areas that should be included in the measurements. This area will remain the same for the rest of the process. Then press OK to continue.");
					if(selectionType() < 0)
						{//snapback to same function if no selection this loop can continue on forever if no selection is ever made
						waitForSelection();// this selection area will be saved and reapplied to every image in at the same relative location
						return;
						}
					//store the selection area as a ROI to subtract background later
					roiManager("add");
					//rename the ROI as total selected area
					roiManager("Select", 0);
		 			roiManager("save", roiStaticNameArea);
		 			//make sure this loop isn't triggered again by setting the boolean that must be true to enter this loop to false
					firstRun = false;
					run("Clear Outside");
	 			}
	 			else
		 			{//if this isn't the firstRun then we should already have the roiStaticArea saved
						roiManager("open", roiStaticNameArea);
						roiManager("Select", 0);//select the first roi
						run("Clear Outside"); 
		 			}
	 		}
 	thresholdOpen = false;//set thresholdOpen to false right before maskThreshold() function. Once the maskThreshold() function runs once it will set thresholdOpen to true. This alllows a doOnce loop.
	wait(500);//wait a half second there (for stability)
	maskThreshold();//maskThreshold then calls focusQueryChannel()
}
////
function maskThreshold()
{
	setThreshold(minThreshold,maxThreshold);//load the threshold module with the parameters input at the beginning of the macro
	run("Threshold...");//open the threshold dialog
	if(manualThreshold)
		{//if we are in manualThreshold mode then wait for the user to set the image to binary
			while(is("binary") == false)
				{
					wait(1000);
				}
		}else//if we are in automatic mode then convert to mask programatically
			{
				run("Convert to Mask");
				setStatus("Threshold applied");
			}
	if(watershed)
	{//watershed so that the cell ROIs are seperated
		run("Watershed");
		setStatus("Watershed applied");
	}
	if(dilate)
	{//optional dilate
		run("Dilate");
		setStatus("Dilate applied");
	}
	
	analPartSettings = "size="+minParticleSize+"-"+maxParticleSize+" pixel circularity="+minCircularity+"-"+maxCircularity+" clear add";
	run("Analyze Particles...", analPartSettings);//analyze particles once the threshold has been applied
	////////////////////////////////////////////////////Quality check
	showWindows();//make sure the images are available to the macro
	selectWindow(maskingName + " analysis");//bring the masking channel back by selecting the system clipboard. The clipboard was defined and copied in the focusMaskingChannel() function
	setOption("Show All", true);//show the user the ROIs and allow them to add any missed ROIs and then continue to measurements
	waitForUser("Delete any incorrect ROIs and add any missed ROIs then press OK to continue.");
	////////////////////////////////////////////////////End of quality check
	hideWindows();//hide the images for greater performance
	if(manualSelection)
	{//if in manualSelection then get the unique file name mask
		roiQueryArea = saveDir + roiSaveDir  + File.name + queryROISuffix;
		roiBGArea = saveDir + roiSaveDir + File.name + backgroundROISuffix;
	}else
		{//if we aren't in manual selection then get the static mask
			roiQueryArea = saveDir + roiSaveDir  + queryROISuffix;
			roiBGArea = saveDir + roiSaveDir + backgroundROISuffix;
		}
	roiManager("save", roiQueryArea);//save the ROIs for the end user and the program to look up later 
	focusQueryChannel();//return to the query channel to make the measurements in focusQueryChannel() which then calls the final function in the processing loop, openNextImage()
}
////
function focusQueryChannel()
{
	//lets get the query channel and assign it to a variable
	if(queryChannel == "")//if the query channel is unknown
	{
	//find and set focus to the query channel
	//we will use a dialog box with a dropdown menu of all current images
	//then save the choice which was made and use the string to select an open window
	Dialog.create("Select the query channel");
	Dialog.addChoice("Current images",images);
	Dialog.show();
	queryWindow = Dialog.getChoice();
		if(indexOf(queryWindow, "blue") != -1)
		{
		queryChannel = " (blue)";
		}
		if(indexOf(queryWindow, "red") != -1)
		{
		queryChannel = " (red)";
		}
		if(indexOf(queryWindow, "green") != -1)
		{
		queryChannel = " (green)";
		}
	}
	showWindows();
	queryName = File.name + queryChannel;
	if(queryName == maskingName)//if the query channel is the same as the masking channel
	{
		selectWindow(maskingName + " analysis");
	}else
	{
	selectWindow(queryName);
	}
	//make the measurements
	Measure();
}
////
function Measure()
{
	openAndSetFocusROI();//open and set the focus to the ROI manager
	getBackgroundArea();//make the background area mask
	roiManager("select", roiManager("count")-2);//select the second from last ROI
	roiManager("Delete");//remove the ROI which is the total area mask that was used to make the BG roi as it isn't needed in the final measurements
	roiManager("select", roiManager("count")-1);//last ROI
	renameROIs();//rename the roi labels
	roiManager("deselect");//deselect the background measurement and select all before measuring
	run("Select All");
	roiManager("Measure");
	setStatus("Background measurement complete");
	setStatus("ROI measurement complete");
	moveBackgroundMeasurement();//moves the background signal to another column and sets the internal variable to use in the next function
	addBackgroundSubtractionColumn();//add the background subtraction column to the results section
	saveResults();//save the results
	hideWindows();//hide the windows
	openNextImage();//open the next image
}
////
function openNextImage()
{//if needed open the next image and restart the macro else exit the macro
	run("Close All");//close everything to clean up
	currentImage++;//open the next image
		if(currentImage <= (list.length-1))
			{//if the next image is within the array of images that we have meaning that it exists then
				print("Current image ID: "+ currentImage);
				if(batch)
						{//if we are in batch mode then continue
							roiManager("reset");//clear the ROI manager
							fileName = list[currentImage];
							filePath = dir+fileName;
							if(File.exists(filePath))
								{
								open(filePath);
								wait(1000);//wait for 1 second
								initializeImage();//initializeImage then calls focusMaskingChannel()
								}
						}
						else
							{//else if we are not in batch processing mode then reopen the original file
								setStatus("Opening the first image.");
								open(originalFilePath);
							}
			}
			else//if the next image doesn't exist then we are done
				{
					exitMacro();
				}
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#############################
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////End of the main program loop
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#############################
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#############################
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////Start of the child functions
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////#############################
function exitMacro()
{
	waitForUser("No more images found. Macro is now exiting.");
}
function renameROIs()
{
	setStatus("ROI renaming initiated");
		for (i = 0; i < getValue("results.count"); i++) 
	{
		{
			roiManager("select", i);//select current ROI
			label = queryChannel + i; //create the label for the roi
			roiManager("Rename", label);//rename the last ROI as the background 
		}
	}
	roiManager("select", roiManager("count")-1);//last ROI
	roiManager("Rename", "Background");//rename the last ROI as the background area
	setStatus("ROI renaming complete.");
}
function moveBackgroundMeasurement()
{
	backgroundSignal = getValue("results.count")+1;
	setResult("Background",0,backgroundSignal);
	IJ.deleteRows(getValue("results.count")+1, getValue("results.count")+1);
	setStatus("Relocated background measurement.");
}
function addBackgroundSubtractionColumn()
{//add the background subtracted colum to the data
	average = 0;
	for (i = 0; i < getValue("results.count"); i++) 
	{
		{
			progress = (i/("results.count"));///get the progress value
			showProgress(progress);//update the progress bar
			value = "=MAX(0,"+getResult("Mean", i)+"-"+backgroundSignal+")";//this will set the value of the cell to an excel subtraction formulate that subtracts the bkgrnd signal from the current signal
			setResult("Mean(-Background)", i, value);
		}
	}
	label = "Average";
	totalAverage = "=average(J2:J"+(i+1)+")";
	setResult("Mean(-Background)", nResults, label);
	setResult("Mean(-Background)", nResults, totalAverage);
	setStatus("Done formatting results for: " + File.nameWithoutExtension);
}
function saveResults()
{
	saveFileName = saveDir+resultsSaveDir+File.name+resultsSaveName;//set the saved results file name
	saveAs("results", saveFileName);//save the results as a .xlxs
	setStatus("Results saved to: "+saveFileName);//print the saveFileName to the log so the end-user can see where the .xlxs result is saved to
}
function getBackgroundArea()
{
	
	//clear the ROI manager
	roiManager("reset");
	//get the saved rois that are the mask
	roiManager("open", roiQueryArea);
	//get the total area measurement which is the background
	roiManager("open", roiBGArea);
	//select all and use XOR to create BG mask
	run("Select All");
	roiManager("XOR");
	setStatus("Holes have been made using selection area in background mask");
	if(roiManager("count")>2)//if there are query areas
	{
	roiManager("Add");//add the background mask
	setStatus("Added background mask.");
	}
	//bg area has now been added to the ROI manager
	setStatus("Background mask creation done.");
}
function requestSettings()
{
		run("Set Measurements...", "area mean min perimeter median display redirect=None decimal=3");//set the measurements so that we have a predictable results table to work with
		createParameterDialog();//create the dialog box/ main menu
		Dialog.show();//show the dialog box
		retrieveParameterDialog();//save all the variables from the dialog box outputs
		printSettings();//print the debug settings
		setStatus("Settings have been retrieved from parameter dialog.");
}
function createParameterDialog()
{//request all the variables for the macro using a dialog box
		Dialog.create("Set Parameters for the Quantification Process");
		Dialog.setLocation((screenWidth/2),screenHeight/2);
		Dialog.addNumber("Minimum threshold range.", minThreshold);
		Dialog.addNumber("Maximum threshold range.", maxThreshold);
		Dialog.addNumber("Minimum size to be measured in pixels.", minParticleSize);
		Dialog.addNumber("Maximum size to be measured in pixels.", maxParticleSize);
		Dialog.addNumber("Minimum circularity to be measured.", minCircularity);
		Dialog.addNumber("Maximum circularity to be measured.", maxCircularity);
		Dialog.addCheckbox("Apply threshold manually.", manualThreshold);
		Dialog.addCheckbox("Select working area manually.", manualSelection);
		Dialog.addCheckbox("Process multiple images.", batch);
		Dialog.addCheckbox("Apply the watershed function to the ROIs.", watershed);
		Dialog.addCheckbox("Apply the dilate function to the ROIs.", dilate);
		setStatus("Parameter dialog created.");
}
function retrieveParameterDialog()
{//save all the variables for the macro from the dialog box
		minThreshold = Dialog.getNumber();
		maxThreshold = Dialog.getNumber();
		minParticleSize = Dialog.getNumber();
		maxParticleSize = Dialog.getNumber();
		minCircularity = Dialog.getNumber();
		maxCircularity = Dialog.getNumber();
		manualThreshold = Dialog.getCheckbox();
		manualSelection = Dialog.getCheckbox();
		batch = Dialog.getCheckbox();
		watershed = Dialog.getCheckbox();
		dilate = Dialog.getCheckbox();
		setStatus("Parameter dialog variables retrieved.");
}
function printSettings()
{//print the settings for debugging purposes
		setStatus('[USER SETTINGS]');
		setStatus('minThreshold = ' + minThreshold);
		setStatus('maxThreshold = ' + maxThreshold);
		setStatus('minParticleSize = ' + minParticleSize);
		setStatus('maxParticleSize = ' + maxParticleSize);
		setStatus('minCircularity = ' + minCircularity);
		setStatus('maxCircularity = ' + maxCircularity);
		setStatus('manualThreshold = ' + manualThreshold);
		setStatus('manualSelection = ' + manualSelection);
		setStatus('batch = ' + batch);
		setStatus('watershed = ' + watershed);
		setStatus('dilate = ' + dilate);
		setStatus('Share these settings and the debug log for troubleshooting errors and when asking for help.');
}
function openAndSetFocusROI()
{//check to see if the ROI manager is open then select the window if so and if not then open the ROI manager and select it
	if(isOpen("ROI Manager"))
	{
		selectWindow("ROI Manager");
	}else
		{
			run("ROI Manager...");
			selectWindow("ROI Manager");
		}
}
function showWindows()
{//Exits batch mode and displays all hidden images.
	if(is("Batch Mode"))
		{
			setBatchMode("exit and display");
			setStatus("Automation disabled");
		}
}
function hideWindows()
{//hide the images to optimize execution
	setBatchMode("hide");
	setStatus("Automation enabled");
}
function displayMessage(messageToDisplay)
{//create a dialog message
	showMessageWithCancel("Instructions",messageToDisplay);
}
function setStatus(status)
{//set the current toolbar status message
	print("Status Update: " + status);
	showStatus(status);
}
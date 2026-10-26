// ==============================================================================
// MACRO: Automated Spore and Germinated Cell Counter (Phase Contrast)
// ==============================================================================
// Description: Automates the detection and counting of phase-bright dormant 
// spores and phase-dark germinated/vegetative cells using grayscale thresholding 
// and local maxima detection.
// ==============================================================================

// --- USER INTERFACE DIALOG ---
Dialog.create("Spore and Germinated Cell Counter");

Dialog.addMessage("--- PHASE-DARK CELLS (BLUE) ---\n \n" +
"IF: True phase-dark cells are missed (especially on dark backgrounds).\n" +
"-> Decrease Variable 1 (Warning: too low may misclassify spores!).\n \n" +
"IF: Dark phase rings around spores are falsely counted as blue cells.\n" +
"-> Increase Variable 2.\n \n" +
"IF: A true germinated cell is fragmented or disappears.\n" +
"-> Decrease Variable 2.\n");

Dialog.addNumber("Variable 1  : Dark Cell Sensitivity (Lower = detects in darker areas):", 5);
Dialog.addNumber("Variable 2  : Spore Ring Artifact Filter (Morphological opening):                                      ", 8);
Dialog.addNumber("Variable 3  : Minimum Cell Size (in pixels):                                           ", 30);

Dialog.addMessage("\n \n--- PHASE-BRIGHT SPORES (RED) ---\n \n" +
"IF: Dull or gray spores are missed.\n" +
"-> Decrease Variable 4 (Detects lower intensity peaks).\n \n" +
"IF: Inter-cellular bright spaces are falsely counted as spores.\n" +
"-> Increase Variable 5.\n \n" +
"IF: Bright optical halos around spores generate double counts.\n" +
"-> Increase Variable 6 (Erodes the outer bright artifact).\n");

Dialog.addNumber("Variable 4 : Spore Sensitivity (Lower = higher detection rate):                                ", 15);
Dialog.addNumber("Variable 5 : Inter-Cellular Halo Filter (Exclusion mask radius):                                                            ", 15);
Dialog.addNumber("Variable 6 : Spore Edge Artifact Filter (Erosion radius):                                                              ", 2);

Dialog.show();

// Retrieve user inputs
var_dark_threshold = Dialog.getNumber();
var_ring_filter = Dialog.getNumber();
var_min_size = Dialog.getNumber();
var_spore_prominence = Dialog.getNumber();
var_halo_mask = Dialog.getNumber();
var_spore_artifact = Dialog.getNumber();


// --- INITIALIZATION ---
run("Clear Results");      // Clear previous measurement results
run("Remove Overlay");     // Clear previous ROI overlays (red/blue circles)
roiManager("reset");       // Clear ROI Manager
imageTitle = getTitle();   // Store the original image title
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel"); // Force pixel measurements


// ==============================================================================
// STEP 1: OPTICAL PREPARATION (BACKGROUND ILLUMINATION CORRECTION)
// ==============================================================================
// Create two blurred versions of the image to isolate local details from global illumination.
run("8-bit"); 

// Sharp Image: Slight blur to denoise and smooth pixel granularity
selectWindow(imageTitle);
run("Duplicate...", "title=Sharp");
run("Gaussian Blur...", "sigma=1.5"); 

// Blurred Image: Heavy blur to extract the uneven background illumination
selectWindow(imageTitle);
run("Duplicate...", "title=Blurred");
run("Gaussian Blur...", "sigma=8"); 


// ==============================================================================
// STEP 2: PHASE-DARK CELL DETECTION (GERMINATED/VEGETATIVE CELLS)
// ==============================================================================
// Blurred - Sharp = Isolates phase-dark objects by pseudo-flatfield correction
imageCalculator("Subtract create", "Blurred", "Sharp");
rename("Dark_Cells_Image"); 

// Apply threshold to create a binary mask based on user sensitivity (Variable 1)
setThreshold(var_dark_threshold, 255);
setOption("BlackBackground", true);
run("Convert to Mask");

// MORPHOLOGICAL OPENING (Variable 2): 
// The Minimum filter (erosion on white objects) destroys thin spore phase rings.
run("Minimum...", "radius=" + var_ring_filter);
// The Maximum filter (dilation) restores the surviving dark cells to their original size.
run("Maximum...", "radius=" + var_ring_filter);

// Shape analysis to exclude noise and artifacts (Variable 3)
run("Analyze Particles...", "size=" + var_min_size + "-Infinity circularity=0.30-1.00 show=Masks clear add");
rename("Pure_Dark_Cells_Mask");
count_dark_cells = roiManager("count"); // Retrieve the number of detected dark cells


// ==============================================================================
// STEP 3: EXCLUSION MASK GENERATION
// ==============================================================================
// Dilate the dark cells mask to cover both the cells and their surrounding optical halos.
// This prevents inter-cellular brightness from being misidentified as spores (Variable 5).
selectWindow("Pure_Dark_Cells_Mask");
run("Duplicate...", "title=Exclusion_Mask");
run("Maximum...", "radius=" + var_halo_mask); 


// ==============================================================================
// STEP 4: PHASE-BRIGHT SPORE DETECTION
// ==============================================================================
// Sharp - Blurred = Isolates phase-bright objects (spores).
imageCalculator("Subtract create", "Sharp", "Blurred");
rename("Base_Spores"); 

// Subtract the exclusion mask to ignore areas adjacent to germinated cells
imageCalculator("Subtract", "Base_Spores", "Exclusion_Mask");

// SPORE HALO FILTER (Variable 6):
// Erode the remaining signal to eliminate thin bright artifacts around true spores.
run("Minimum...", "radius=" + var_spore_artifact);
run("Gaussian Blur...", "sigma=1"); // Slight smoothing to define clear intensity peaks

// Detect local maxima (intensity peaks) based on user sensitivity (Variable 4)
run("Find Maxima...", "prominence=" + var_spore_prominence + " output=List"); 
count_spores = nResults;


// ==============================================================================
// STEP 5: VISUAL OVERLAY AND CLEANUP
// ==============================================================================
selectWindow(imageTitle);

// Draw exact outlines of Phase-Dark Cells in BLUE
if (count_dark_cells > 0) {
    for (i = 0; i < count_dark_cells; i++) {
        roiManager("select", i);
        run("Add Selection...", "stroke=blue width=2");
    }
    run("Select None");
}

// Draw standard circular bounding boxes around Spore centroids in RED
if (count_spores > 0) {
    for (i = 0; i < count_spores; i++) {
        x = getResult("X", i); 
        y = getResult("Y", i); 
        makeOval(x-10, y-10, 20, 20); 
        run("Add Selection...", "stroke=red width=2");
    }
    run("Select None");
}

// Calculate percentages and print summary to the Log/Results window
total_cells = count_spores + count_dark_cells;
pct_spores = 0;
pct_dark_cells = 0;

if (total_cells > 0) {
    pct_spores = (count_spores / total_cells) * 100;
    pct_dark_cells = (count_dark_cells / total_cells) * 100;
}

print("=== Analysis Results (" + imageTitle + ") ===");
print("Spores (Red) = " + count_spores + " (" + d2s(pct_spores, 1) + "%)");
print("Germinated/Vegetative Cells (Blue) = " + count_dark_cells + " (" + d2s(pct_dark_cells, 1) + "%)");
print("Total Count = " + total_cells);

// Memory cleanup: close intermediate processing windows
selectWindow("Sharp"); close();
selectWindow("Blurred"); close();
selectWindow("Dark_Cells_Image"); close();
selectWindow("Pure_Dark_Cells_Mask"); close();
selectWindow("Exclusion_Mask"); close();
selectWindow("Base_Spores"); close();
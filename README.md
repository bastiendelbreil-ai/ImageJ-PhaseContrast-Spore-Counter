# ImageJ Phase-Contrast Spore Counter

An ImageJ/Fiji macro designed for the automated detection and counting of phase-bright dormant spores and phase-dark germinated/vegetative cells from phase-contrast microscopy images.

## ⚙️ Requirements
* **Fiji** (ImageJ bundled with standard plugins)
* No additional external plugins or dependencies are required.

## 🚀 Usage Instructions
1. Open **Fiji**.
2. Drag and drop the `spore_germination_counter.ijm` file into the Fiji window to open the script editor.
3. Click on **Run**.
4. A dialog box will appear. You can adjust the detection sensitivities (Variables 1 to 6) based on your background illumination and cell sizes. Default values are provided for standard phase-contrast images.
5. The macro will automatically outline phase-dark cells in **blue** and mark phase-bright spores with **red** circular bounding boxes.
6. Results (absolute counts and percentages) are printed directly in the Log/Results window.

## 📂 Test Data
A `test_images/` directory is provided in this repository. It contains representative TIFF crops to test the macro and visualize the default thresholding parameters.

## 📝 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author
**Bastien** 
*(Link to Zenodo DOI will be added here upon release)*

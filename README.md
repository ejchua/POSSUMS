# POSSUMS
MATLAB scripts to (1) conduct the porewater sampling routine and (2) analyze POSSUMS data.

POSSUMS Flow Injection Analysis
Emily Chua
Last updated: July 2020

Run the MATLAB scripts in the following order.

Important notes:
•	Raw FabGuard data should be exported as .dat files and saved with the following filename convention: “yy_MM_dd-HH_mm”
•	The porewater sampling log data are automatically saved as .txt files with the following filename convention: “PWSampler_MM_dd_yyyy hh_mm”

Step 1: Data Processing
This step only has to be run once for all gases.
LoadMIMSData.m
Function: Transforms raw FabGuard text file into MATLAB table
Input folder: “RawData\FabGuard” (contains FabGuard .dat files)
Output folder: “ProcessedData\FabGuard” (saves .mat file)
LoadPWData.m
Function: Transforms raw porewater sampler data log into MATLAB table
Input folder: “RawData\PWLog” (contains porewater log .txt files)
Output folder: “ProcessedData\PWLog” (saves .mat file)

Step 2: Peak Finding
This step must be run for each gas of interest.  The current scripts are able to analyze m/z 15, 28, 32, 40, and 44 (CH4, N2, O2, Ar, and CO2); for other gases, they need to be modified.
FindMIMSTimepts.m
Function: Finds the start and stop indices for the peaks and the baseline intervals.  The peak start index is based on the switch to Position B, plus a user-defined delay period; you will be prompted to set this offset, as well as the peak width.  This will require some experimenting, as these parameters will be unique to the data set (the offset depends on factors such as the flow rate, and the peak width depends on factors such as the analyte concentration).
Input folders: “ProcessedData\FabGuard” and “ProcessedData\PWLog”
Output folder: “ProcessedData\Timepts\GAS” (GAS = CH4, N2, Or, Ar, or CO2)

Step 3: Peak Analysis
PeakIntegration.m
Function: Baseline-corrects the peaks and integrates them
Input folder: “ProcessedData\FabGuard” and“ProcessedData\Timepts\GAS” (GAS = CH4, N2, Or, Ar, or CO2) 
Output folder: “Output\PeakAreas\GAS”

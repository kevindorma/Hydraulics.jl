<!-- Index -->

## Hydraulics.jl documentation

Refer to the Jupyter notebook file HydraulicsExample.ipynb for working examples. Also refer to the example spreadsheet inputHydraulicsExample.xlsx.

Line sizing is based on two parameters:

1. Pressure drop per 100 m.
2. Erosional velocity determined by C factor (SI). v_max = C / sqrt(rho), where C = 120 is typical (equivalent to C = 100 for Imperial units in API 14E).

Hydraulic calculations are standard pressure drop for piping and fittings.

* Halaand correlation for friction factor.
* 3K method used for calculating the loss coefficient for fittings.
* A very large list of piping components can be included for each line segment.

Units of measure used in the package are:

* Flow rate, kg/h
* Pressure, kPaa
* Diameter, mm
* Piping length, m

## Input Files

Performing line sizing or hydraulic (pressure drop) calculations requires standard piping data (tabulated with the Hydraulic module SRC code):

* pipe material (roughness)
* pipe schedule (for estimating the nominal pipe size)

We also need fluid properties for the specific case. This is a separate tab in the input sheet.

Refer to the example file Hydraulics_example.xlsx as a sample input file. You could use a CSV file for the input data, but then you would need to ensure that all of the piping data matches the available choices (dropdown menus in a spreadsheet is more convenient).

A line sizing calculation requires a spreadsheet table with the following data:

* Segment: Descriptor of the segment. Must be a unique in this table. This could be alphanumeric (A, B, C, or 1, 2, 3). A segment must have the same fluid flow rate, fluid properties, line size.
* LineTag: optional, detailed text description of the line. Typically the line number from the PnID.
* Description: text descrption of the line.
* PnID: optional, text description of the drawing reference
* fluidName: discrete field (taken from fluid property table) to identify the fluid
* Schedule: discrete field (taken from the pipe schedule table) to identify the pipe wall thickness
* Material: discrete field (taken from the pipe material table) to identify the pipe wall rooughness
* massFlow: nominal flowrate in kg/h. Consider this to be the normal flow rate.
* margin: margin applied to the flowrate for the line sizing calculation.
* fricionCsi: friction C factor, in SI units. C = 120 is considered typical, and is equivalent to C = 100 for Imperial units from API-12.
* kPaPer100m: design pressure gradient in kPa per 100 m.

A hydraulic calculation requires a CSV file or spreadsheet table with the following data:

* Segment: Descriptor of the segment, typically a PFD stream number or a PnID line number. Must be a unique in this table. This could also be alphanumeric (A, B, C, or 1, 2, 3). A segment must have the same fluid flow rate, fluid properties, line size.
* Description: text descrption of the line.
* LineTag: detailed text description of the line. Typically the line number from the PnID.
* NPS: nominal pipe diameter (taken from pipe NPS table) to identify the pipe diameter.
* Schedule: discrete field (taken from the pipe schedule table) to identify the pipe wall thickness
* Material: discrete field (taken from the pipe material table) to identify the pipe wall rooughness
* PnID: optional, text description of the drawing reference (nope)
* fluidName: discrete field (taken from fluid property table) to identify the fluid
* inletP_kPaa: pressure at pipe inlet
* massFlow: nominal flowrate in kg/h. Consider this to be the normal flow rate.
* margin: margin applied to the flowrate for the line sizing calculation.

Pipe lengths and fitting counts are tabulated separately for each line segment:

* Segment: Descriptor of the segment, typically a PFD stream number or a PnID line number. Must be a unique in this table. This could also be alphanumeric (A, B, C, or 1, 2, 3). A segment must have the same fluid flow rate, fluid properties, line size.
* fittingType: discrete field (taken from the fitting3K list) to identify the type of fitting. Example, PIPE or EL45-THD-STD
* num_length_m: either the total number of fittings of the given type, or the total length of pipe specified.
* comment: optional comment
* revision: optional revision comment


### Line sizing functions

* getLineSize(lines,fluidList)
    * given the lines (line sizing) dataframe, return line sizing values in dataframe
    * Segment: segment in df
    * mmDP100: ID based on kPa per 100 m
    * mmErosion: ID based on erosion C value
    * mmNeeded: larger of the two values
    * Schedule: the line schedule to be used
* getLargerNPS(ourIDmm, ourSchedule)
    * return the NPS of the next larger pipe (given the schedule)
* incrementLineSize(rowNum, lineSizeDF, increment)
    * increases (or decreases) the line NPS (increment is 1 or -1)
* sizing2hydraulics(sizingDF, chosenLineSizeDF)
    * copy the line sizing dataframe to a hydraulics dataframes.
    * all line lengths pre-populated at 100 m.
* sizing2fittingList(sizingDF, chosenLineSizeDF)
    * populates a simple fitting list with each line specified in the sizing DF, and makes each line 100 m long

### Hydraulic functions 

* getSegmentDP(lines, fittingList)
    * lines describes the hydraulics, fittingList has the piping details, fluidList is the fluid
    * this calculates the pressure drop throuch each item listed in the fittingList
    * then the pressure drop for each segment is compiled
    * function returns a vector of pressure drops
* getReynolds(df)
    * given the hydraulic dataframe df, return dataframe with
        * velocity, Reynolds, friction factor, density, diameterMM, diameterInch
* calcMoodyF(Reynolds,eD)
    * Reynolds number and e/D, where e is roughness (in mm) and D is ID in mm
    * return floating (or array of float) for Moody friction factor
    * Halaand correlation is used for the Moody friction factor.
    * sorry, there is no checking for the pipe Reynolds number is in the turbulent regime.


### Utility DataFrames
* npsList: list of available NPS. used for dropdownlist in spreadsheet
* schedList: list of different pipe schedules. used for dropdown list in spreadsheet
* pipeRoughness: tabulated roughness (mm) for different piping materials. used for dropdownlist in spreadsheet.
* fitting3K: 3K factors for fittings
* IDmm: list of pipe NPS, Schedule and ID in mm. Can also get the pipe OD.
* pipeTable: tabulated pipe dimensions, NPS x Schedule


Refer to the Jupyter notebook file HydraulicsExample.ipynb for working examples and a typical calculation sequence.



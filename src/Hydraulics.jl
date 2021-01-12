# November, 2020
# Kevin Dorma
# module for common hydraulic calculations
# rev 0

# I need to make some decisions about how to interace with these functions
# I assume that I use dataframes to store information about sizing lines and general hydraulics
# then I will execute a function and it will return a result, but not change the raw information
# size lines
    # Input dataframe for describing the lines
    # Output line descriptor, pipe schedule, size criteria DP/100 and C, IDmm for each criteria and the chosen IDmm
# pick NPS will return the next size larger for NPS.This will be the chosen size.
# we will have utility functions for increasing or decreasing the NPS by 1. 


module Hydraulics

using DataFrames
using CSV
#using ExcelFiles

export calcMoodyF
export addPipeProperties, addFluidProperties, getReynolds, getSegmentDP
export getLineSize, getListLargerNPS, getLargerNPS



# these are the reference data.
# and this needs to be loaded correctly when we use the code in a module
include("npsList.jl")
include("schedList.jl")
include("pipeRoughnessList.jl")
include("fitting3K.jl")
include("pipeIDlist.jl")

#schedList = CSV.File("schedList.csv") |> DataFrame
#pipeRoughness = CSV.File("pipeRoughness.csv") |> DataFrame
#fitting3K = CSV.File("fitting3K.csv") |> DataFrame
#IDmm = CSV.File("pipeIDlist.csv") |> DataFrame
## not used
#pipeTable = CSV.read("pipeIDtable.csv");


function packageInfo()
    # return information about the package as a string
    return("Hydraulics package, Kevin Dorma. Written in Julia, December 2020.")
end

# need function to append piping data
# later


function calcMoodyF(Reynolds,eD)
    # Moody friction factor, this is Halaand
    # eD is e/D relative roughness
    # Reynolds is Reynolds number
    invSqrtF = -1.8 .* log10.((eD ./ 3.70) .^ 1.11 + 6.9 ./ Reynolds)
    moodyF = (1 ./ (invSqrtF .^2) )
    return (moodyF)
end

function checkFittingList(fittingList)
    # fittingList is our list of fittings, fittingReference is the generic data
    # go through the list of fittings (fittingList) and compare with the reference list (possibly our fitting3K global list)
    # return items that are not found
    errorList = DataFrame(message = String[], entry=Int64[], Segment=String[], fittingType=String[])
    for i = 1:(size(fittingList)[1])
        thisFitting = fittingList[i,:fittingType]
        match = fitting3K[fitting3K.fittingType .== thisFitting,:]
        if ((size(match)[1]) == 0)
            push!(errorList, ("Fitting not found in row", i, fittingList[i,:Segment], fittingList[i,:fittingType] ))
        end
    end
    return (errorList)
end



function checkLineList(lines,fluidList)
    # go through our list of lines and compare with our reference lists
    # return the line items that are not found
    errorList = DataFrame(message = String[], entry=Int64[], Segment=String[], NPS=Float64[], Schedule=String[], material=String[], fluidName=String[])
    for i = 1:(size(lines)[1])
        # NPS
        thisItem = lines[i,:NPS]
        match = npsList[npsList.NPS .== thisItem,:]
        if ((size(match)[1]) == 0)
            push!(errorList, ("NPS not found in row", i, lines[i,:Segment], lines[i,:NPS], lines[i,:Schedule], lines[i,:Material], lines[i,:fluidName] ))
        end
        # schedule
        thisItem = lines[i,:Schedule]
        match = schedList[schedList.Schedule .== thisItem,:]
        if ((size(match)[1]) == 0)
            push!(errorList, ("Schedule not found in row", i, lines[i,:Segment], lines[i,:NPS], lines[i,:Schedule], lines[i,:Material], lines[i,:fluidName] ))
        end
        # roughness material
        thisItem = lines[i,:Material]
        match = pipeRoughness[pipeRoughness.Material .== thisItem,:]
        if ((size(match)[1]) == 0)
            push!(errorList, ("Material not found in row", i, lines[i,:Segment], lines[i,:NPS], lines[i,:Schedule], lines[i,:Material], lines[i,:fluidName] ))
        end
        # fluid
        thisItem = lines[i,:fluidName]
        match = fluidList[fluidList.fluidName .== thisItem,:]
        if ((size(match)[1]) == 0)
            push!(errorList, ("FluidName not found in row", i, lines[i,:Segment], lines[i,:NPS], lines[i,:Schedule], lines[i,:Material], lines[i,:fluidName] ))
        end
    end
    return (errorList)
end


function addPipeProperties(df)
    # roughness, IDmm, eD ratio
    # this appends columns to df
    # used either line sizing or hydraulic calculations

    df[:,:roughnessMM] .= 0.0
    df[:,:IDmm] .= 0.0

    for i = 1:(size(df)[1])
        df[i,:roughnessMM]=pipeRoughness[df[i,:Material] .== pipeRoughness[:,:Material],:roughnessMM][1]
        df[i,:IDmm]= IDmm[(df[i,:NPS] .== IDmm[:,:NPS]) .& (df[i,:Schedule] .== IDmm[:,:Schedule]),:Idmm][1]
    end

    return (0.0)
end

function addFluidProperties(df,fluidList)
    # extract the density, viscosity and whatever else is needed from the fluidList
    # Add this to the df
    # used either line sizing or hydraulic calculations

    

    df[:,:rho_kgm3] .= 0.0
    df[:,:mu_mPas] .= 0.0
    df[:,:roughnessMM] .= 0.0


    for i = 1:(size(df)[1])
        df[i,:rho_kgm3] = fluidList[df[i,:fluidName] .== fluidList[:,:fluidName], :rho_kgm3][1]
        df[i,:mu_mPas]  = fluidList[df[i,:fluidName] .== fluidList[:,:fluidName], :mu_mPas][1]
        df[i,:roughnessMM]  = pipeRoughness[df[i,:Material] .== pipeRoughness[:,:Material], :roughnessMM][1]
    end

    return (0.0)
end



function lineSizeDP(df)
    # this is for sizing lines based on pressure drop kPa per 100 m, return the ID in mm
    # very convenient form straight out of Perrys handbook
    # uses friction factor correlation from Chen
    # Do not modify the original data in df

    g = 9.80665
    Sf = df.kPaPer100m*1000 ./ (df.rho_kgm3*g*100)
    q = df.massFlow .* df.margin ./(df.rho_kgm3*3600)
    eps = (df.roughnessMM/1000)
    kinVisc = (df.mu_mPas/1000) ./ df.rho_kgm3
    termA = ((eps.^5)*g .* Sf ./ (q.^2)).^0.25
    termB = ((kinVisc .^ 5)./((q.^3) .* Sf * g )).^0.2
    termC = 0.125*(termA .+ termB).^0.2
    returnValue = (1000*(termC .* (q.^2) ./ (g*Sf)).^0.2)
    return (returnValue)
end

function lineSizeErosion(df)
    # df is the dataframe with hydraulic information
    # this is the erosion C factor method
    # C = v/sqrt(rho), with v in m/s and rho in kg/m3
    # for most service, C = 120, this is similar to C = 100 for imperial units
    # return the ID in mm

    g = 9.80665
    maxVeloc = df.frictionCsi ./ sqrt.(df.rho_kgm3)
    q = df.massFlow .* df.margin ./(df.rho_kgm3*3600)
    area = q ./ maxVeloc
    returnValue = (sqrt.(4*area ./ pi )*1000.0)
    return (returnValue)
end

function getLineSize(df,fluidList)
    # from the calculated line size for the two different methods, determine the required line size
    
    addFluidProperties(df,fluidList)
    
    theSchedule = df[:,:Schedule]

    theSegment = df[:,:Segment]

    tempDP100 = lineSizeDP(df)
    tempErosion = lineSizeErosion(df)
    tempNeeded = tempErosion[:] + tempDP100[:]
    for j in 1:size(tempDP100)[1]
        tempNeeded[j] =max(tempDP100[j], tempErosion[j])
    end
    returnValue = DataFrame(Segment = theSegment, mmDP100 = tempDP100, mmErosion = tempErosion, mmNeeded = tempNeeded, Schedule = theSchedule)
    return (returnValue)
end

# I need a function to pick the next larger line size given the pipe schedule


function getLargerNPS(ourIDmm, ourSchedule)
    # from the common list of line sizes, pick the pipe size that matches the required schedule
    # and is the next larger that the required ID
    # this works for a single line size
    ourScheduleList = IDmm[IDmm[:,:Schedule] .== ourSchedule, :];
    refinedList = ourScheduleList[(ourScheduleList[:,:Idmm] .- ourIDmm) .> 0.0,:];
    theMinID = minimum(refinedList[:,:Idmm])
    ourNPS = refinedList[(refinedList[:,:Idmm] .== theMinID), :NPS]

    return (ourNPS)
end


function getListLargerNPS(lineSizeDF)
    # we will use the required line size and schedule and return the NPS and actual ID
    diamList = DataFrame(Segment=String[], NPS=Float64[], Schedule=String[], IDmm=Float64[])
    for i = 1:(size(lineSizeDF)[1])
        ourSchedule = lineSizeDF[i,:Schedule];
        ourIDmm = lineSizeDF[i,:mmNeeded]
        ourScheduleList = IDmm[IDmm[:,:Schedule] .== ourSchedule, :];
        refinedList = ourScheduleList[(ourScheduleList[:,:Idmm] .- ourIDmm) .> 0.0,:];
        theMinID = minimum(refinedList[:,:Idmm])
        ourNPS = refinedList[(refinedList[:,:Idmm] .== theMinID), :NPS][1]

        push!(diamList, (lineSizeDF[i,:Segment], ourNPS, ourSchedule, theMinID))
    end
    return (diamList)
end

function sizing2hydraulics(sizingDF, chosenLineSizeDF)
    # given the line sizing DF, copy the info into hydraulics dataframe
    # chosenSizeDF contains the NPS and Schedule
    # return the hydraulics DF
    # we also need a simple fittingDF, but this is done with a separate function
    hydraulicsDF = DataFrame(Segment=String[], Description=String[], LineTag=String[], PnID=String[], NPS=Float64[], Schedule=String[],
		Material=String[],	fluidName=[],	inletP_kPaa=[],	massFlow=Float64[],	margin=Float64[])
    for i = 1:(size(sizingDF)[1])
        push!(hydraulicsDF, (sizingDF[i,:Segment], sizingDF[i,:Description],
                sizingDF[i,:LineTag], sizingDF[i,:PnID], chosenLineSizeDF[i,:NPS],
                chosenLineSizeDF[i,:Schedule], sizingDF[i,:Material], sizingDF[i,:fluidName],
                100.0, sizingDF[i,:massFlow], sizingDF[i,:margin]))
    end
    return(hydraulicsDF)
end

function sizing2fittingList(sizingDF, chosenLineSizeDF)
    # given the line sizing DF, copy the info into the fitting list
    # chosenSizeDF contains the NPS and Schedule
    # return the pre-populsted fittign list DF
    fittingListDF = DataFrame(Segment=String[], fittingType=String[], num_length_m=Float64[], comment=String[], revision=String[])
    
    for i = 1:(size(sizingDF)[1])
        push!(fittingListDF, (sizingDF[i,:Segment], "PIPE", 100.0, "from line sizing", "A"))
    end
    return(fittingListDF)
end




function incrementLineSize(rowNum, lineSizeDF, increment)
    # increment the specified row number needed line size by +1 or -1
    # not the cleanest function, but it works
    
    neededDF = DataFrame(Segment=String[], mmNeeded=Float64[], Schedule=String[])
    
    i = rowNum
    push!(neededDF, (lineSizeDF[i,:Segment], lineSizeDF[i,:IDmm] + increment, lineSizeDF[i,:Schedule]))

    incrementedLines = getListLargerNPS(neededDF)

    lineSizeDF[i,:NPS] = incrementedLines[1,:NPS]
    lineSizeDF[i,:IDmm] = incrementedLines[1,:IDmm]

    return (3.14)
end

function getReynolds(df)
    # preliminary calculations for pipe hydraulics
    # return the velocity, Reynolds, friction factor, density, diameterMM, diameterInch

    theSegment = df.Segment
    diamMM = df.IDmm
    diamInch = diamMM / 25.4
    rho = df.rho_kgm3
    volFlow = df.massFlow .* df.margin ./ df.rho_kgm3
    area = 0.25 * pi * (df.IDmm / 1000.0).^2
    velocity = volFlow ./ area / 3600
    Reynolds = df.rho_kgm3 .* velocity .* (df.IDmm / 1000.0) ./ (df.mu_mPas/1000.0)
    eD = df.roughnessMM ./ df.IDmm
    moodyF = calcMoodyF(Reynolds, eD)
    returnValue = DataFrame(Segment = theSegment, velocity_ms = velocity, rho_kgm3 = rho, Re = Reynolds, frictF = moodyF, IDmm = diamMM, IDinch = diamInch)
    return (returnValue)
end


function elementDP(lines, fittingList)
    # given the hydraulic elements in df (long list of pipe and fittings)
    # and the preliminary values in prelim
    # calculate the DP in each element
    # dp = rho.f. (L/D) v2/2
    # dp = rho K v2/2
    # where I need to calculate K = K1/Re + Kinf*(1 + Kd/Dinch^0.3)
    # can I get all of the pipe segments and use K = Kp * f L/D, where Kp = 1 for pipe
    # return the value for Kp (1 for pipe, 0 for fitting) and the pressure drop in the item
    returnValue = DataFrame(Segment = String[], Kp = Float64[], fittingK=Float64[], pipeK=Float64[], elementK = Float64[], DPkpa = Float64[])
    
    # start with getting Reynolds and other important things
    prelim = getReynolds(lines)

    for i = 1:(size(fittingList)[1])
        theSegment = fittingList[i,:Segment]

        # first we get all of the K values
        valK1 = fitting3K[fitting3K[:,:fittingType] .== fittingList[i,:fittingType],:K1][1]
        valKinf = fitting3K[fitting3K[:,:fittingType] .== fittingList[i,:fittingType],:Kinf][1]
        valKd = fitting3K[fitting3K[:,:fittingType] .== fittingList[i,:fittingType],:Kd][1]
        valKp = fitting3K[fitting3K[:,:fittingType] .== fittingList[i,:fittingType],:Kp][1]

        # now we get the hydraulic properties
        ff = prelim[prelim[:,:Segment] .== fittingList[i,:Segment],:frictF][1]
        rho = prelim[prelim[:,:Segment] .== fittingList[i,:Segment],:rho_kgm3][1]
        idInch = prelim[prelim[:,:Segment] .== fittingList[i,:Segment],:IDinch][1]
        idMM = prelim[prelim[:,:Segment] .== fittingList[i,:Segment],:IDmm][1]
        veloc = prelim[prelim[:,:Segment] .== fittingList[i,:Segment],:velocity_ms][1]
        Re = prelim[prelim[:,:Segment] .== fittingList[i,:Segment],:Re][1]
        
        Kfitting = valK1/Re + valKinf*(1.0 + valKd/(idInch^0.3))

        # pressure drop in kPa
        thisKfitting = fittingList[i,:num_length_m] * Kfitting
        thisKpipe = valKp * ff * fittingList[i,:num_length_m] /(idMM/1000.0) 
        thisK = thisKfitting + thisKpipe
        thisDP = thisK * (0.001 * rho * 0.5 * (veloc)^ 2)

        push!(returnValue, (theSegment, valKp, thisKfitting, thisKpipe, thisK, thisDP))
    end
    return (returnValue)
end

function compileDP(lines, fittingDP)
    # for each entry in lines, sum all of the fittingDP
    returnValue = DataFrame(Segment = String[], segmentK = Float64[], DPkpa = Float64[], inletP = Float64[], outletP = Float64[])

    for i = 1:(size(lines)[1])
        theSegment = lines[i,:Segment]
        theSumK = sum(fittingDP[fittingDP[:,:Segment] .== theSegment,:elementK])
        theSumDP = sum(fittingDP[fittingDP[:,:Segment] .== theSegment,:DPkpa])
        theInletP = lines[i,:inletP_kPaa]
        theOutletP = theInletP - theSumDP
        push!(returnValue, (theSegment, theSumK, theSumDP, theInletP, theOutletP))
    end
    return (returnValue)
end

function getSegmentDP(lines, fittingList, fluidList)
    # lines describes the hydraulics, fittingList has the piping details, fluidList is the fluid

    addFluidProperties(lines,fluidList)
    addPipeProperties(lines)
    fittingDP = elementDP(lines, fittingList)
    returnValue = compileDP(lines, fittingDP)
    return (returnValue)
end

end # module

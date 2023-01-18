using CSV
using DataFrames
using Gtk
using Images
using ImageView
using ProgressBars
using Statistics
using VideoIO
using NativeFileDialog
using GLMakie

include("functions/functions.jl")

filename = pick_file(filterlist="mp4")

f = import_video(filename)

dataOK = "no"

while dataOK == "no"
    ROI = select_ROI(f; n_testframes=50)
    global df = get_values(ROI, f)
    global dataOK = check_quality(df)
end

### for now an "unchecked" exit (by force closing the plot window for instance) will exit the while loop without allowing to save
### should I change the behaviour? (so that "unchecked" behaves as "no" and continues the loop?)

if dataOK == "yes"
    # default export folder and name is same as source video but with extension changed to csv
    exportname = split(filename,".")[1] * ".csv"
    exportpath = save_file(exportname ; filterlist = "csv")
    CSV.write(exportpath, df)
end

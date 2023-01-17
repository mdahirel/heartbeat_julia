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

dataOK="no"

while dataOK == "no"
    ROI = select_ROI(f)
    df = get_values(ROI, f)

    #example plot by channel

    dataOK = check_quality(df)
end

exportpath = save_file(split(filename,".")[1]; filterlist = "csv")
CSV.write(exportpath, df)

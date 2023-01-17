using CSV
using DataFrames
using Gtk
using Images
using ImageView
using ProgressBars
using Statistics
using VideoIO
using NativeFileDialog
using Plots

include("functions/functions.jl")

filename = pick_file(filterlist="mp4")

f = import_video(filename)
ROI = select_ROI(f)
df = get_values(ROI, f)

#example plot
Plots.plot(df[:,"time"], df[:,"valueR"])
xlabel!("time in sec")
ylabel!("average value on red channel")
title!("heartbeat")

exportpath = save_file(split(filename,".")[1]; filterlist = "csv")
CSV.write(exportpath, df)

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

#example plot by channel
pR = Plots.plot(df[:,"time"], df[:,"valueR"],lc=:red); #semi colon suppress return; plot not displayed for now
xlabel!("time in sec");
ylabel!("average value");
title!("red");

pG = Plots.plot(df[:,"time"], df[:,"valueG"],lc=:green);
xlabel!("time in sec");
ylabel!("average value");
title!("green");

pB = Plots.plot(df[:,"time"], df[:,"valueB"],lc=:blue);
xlabel!("time in sec");
ylabel!("average value");
title!("blue");

pRGB = plot(pR,pG,pB, layout=(2,2),size=(1000,800));


io=PipeBuffer()
png(pRGB,io::IO)
ii=load(io);
imshow(ii; canvassize = (1000, 800), name = "Select ROI")




exportpath = save_file(split(filename,".")[1]; filterlist = "csv")
CSV.write(exportpath, df)

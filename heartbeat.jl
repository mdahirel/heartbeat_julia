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
ROI = select_ROI(f)
df = get_values(ROI, f)

#example plot by channel

good_enough = Observable("unchecked")

fig = Figure()

pos = fig[1, 1]
GLMakie.lines(pos, df[:,"time"], df[:,"valueR"], color = "red")
pos2 = fig[1, 2]
GLMakie.lines(pos2, df[:,"time"], df[:,"valueG"], color = "green")
pos3 = fig[1, 3]
GLMakie.lines(pos3, df[:,"time"], df[:,"valueB"], color = "blue")

fig[2, 1] = buttongrid = GridLayout(tellwidth = false)
buttonlabels = ["redo","done"]
buttons = buttongrid[1, 1:2] = [Button(fig, label = l) for l in buttonlabels]

glfw_window = GLMakie.to_native(display(Makie.current_scene()))

on(buttons[1].clicks) do n
    good_enough[] = "no"
    notify(good_enough)
    GLMakie.GLFW.SetWindowShouldClose(glfw_window, true)
end

on(buttons[2].clicks) do y
    good_enough[] = "yes"
    notify(good_enough)
    GLMakie.GLFW.SetWindowShouldClose(glfw_window, true)
end

# to do: find way to force figure to be on focus when called, to avoid double click issue (one to focus, one to click)
fig



exportpath = save_file(split(filename,".")[1]; filterlist = "csv")
CSV.write(exportpath, df)

function import_video(filename)
    io = VideoIO.open(filename)
    f = VideoIO.openvideo(io)
    return f
end



function select_ROI(f; n_testframes::Int64 = 50)

    times = [] ##timestamps of each frame
    img = []

    seekstart(f)
    ### we load a small set of frames (default 2sec at 25 fps, likely enough to see a beat)
    ### in order to determine the coordinates of the ROI
    iter = ProgressBar(1 : n_testframes)
    set_description(iter, "setting up ROI selection GUI")

    for i in iter
        if i == 1
            img = read(f)
        else
            img = cat(img, read(f), dims = 3)
        end
        push!(times, gettime(f))
    end

    ### Building a GUI in which we can select the ROI
    GUIdata = imshow(img; canvassize = (1000, 600), name = "Select ROI")

    set_gtk_property!(GUIdata["gui"]["vbox"], :spacing, 20)
        done = GtkButton("ROI OK", margin_left = 10)
        info = GtkLabel("", xpad = 10, ypad = 10)

    GAccessor.markup(
        info,
        """<span color='#d95f0e'><b>Instructions:</b></span>\n""" *
        """Select Region Of Interest with [Ctrl + click and drag], """ *
        """you can zoom back with [Ctrl + scroll] or [Ctrl + double click].\n""" *
        """Use the video player to decide if the zoomed ROI is OK, """ *
        """then click on \"ROI OK\" button to proceed if it is."""
        )

    GAccessor.line_wrap(info, true)
    push!(GUIdata["gui"]["vbox"][3], done)
    push!(GUIdata["gui"]["vbox"][3], info)

    showall(GUIdata["gui"]["window"])

    ROIcoords = []

    signal_connect(done, "clicked") do widget
        ROIinfo=GUIdata["roi"]["zoomregion"]
        ROIcoords = (
            xlower = ROIinfo.val.currentview.x.left,
            xupper = ROIinfo.val.currentview.x.right,
            ylower = ROIinfo.val.currentview.y.left,
            yupper = ROIinfo.val.currentview.y.right,
            )
        Gtk.destroy(GUIdata["gui"]["window"])
    end

Gtk.waitforsignal(GUIdata["gui"]["window"],:destroy)

return ROIcoords

end



function get_values(ROIcoords, f)   ## needs to move f creation away
    Nframes = counttotalframes(f)
    times = Float64[]
    avgred = Float64[]
    avggreen = Float64[]
    avgblue = Float64[]
    seekstart(f)

    iter = ProgressBar(1 : Nframes)
    set_description(iter, "processing full video")

    for i in iter
        frame = read(f)
        cframe = frame[ROIcoords[:ylower]:ROIcoords[:yupper], ROIcoords[:xlower]:ROIcoords[:xupper]]
        push!(times, gettime(f))
        framemean = mean(cframe)
        push!(avgred, red(framemean))
        push!(avggreen, green(framemean))
        push!(avgblue, blue(framemean))
    end

    #to do: export only one set of value if grayscale (avgred==avggreen==avgblue)?

    df = DataFrame(time = times, valueR = avgred, valueG = avggreen, valueB = avgblue)
    return df
end


function check_quality(df)
    local data_quality = Observable("unchecked")

    fig = Figure()
    #to do: do only one plot if grayscale (avgred==avggreen==avgblue)?
    info = Label(fig[1,1:3], "See whether beats can be distinguished from noise reliably by eye, then decide how to proceed:")

    pos = fig[2, 1]
    GLMakie.lines(pos, df[:,"time"], df[:,"valueR"], color = "red", label ="red channel")
    axislegend()
    pos2 = fig[2, 2]
    GLMakie.lines(pos2, df[:,"time"], df[:,"valueG"], color = "green", label ="green channel")
    axislegend()
    pos3 = fig[2, 3]
    GLMakie.lines(pos3, df[:,"time"], df[:,"valueB"], color = "blue", label ="blue channel")
    axislegend()

    xlab = Label(fig[3,:], "Time (in seconds)")

    fig[4, 2] = buttongrid = GridLayout(tellwidth = false)
    buttonlabels = ["Need to redo","Looks OK, save"]
    buttons = buttongrid[1, 1:2] = [Button(fig, label = l) for l in buttonlabels]

    glfw_window = GLMakie.to_native(display(Makie.current_scene()))

    on(buttons[1].clicks) do n
        data_quality[] = "no"
        notify(data_quality)
        GLMakie.GLFW.SetWindowShouldClose(glfw_window, true)
    end

    on(buttons[2].clicks) do y
        data_quality[] = "yes"
        notify(data_quality)
        GLMakie.GLFW.SetWindowShouldClose(glfw_window, true)
    end

    # to do?? find way to force figure to be on focus when called, to avoid double click issue (one to focus, one to click)
    fig

    wait(display(fig))
    return to_value(data_quality)
end

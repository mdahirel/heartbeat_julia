function import_video(filename)
    io = VideoIO.open(filename)
    f = VideoIO.openvideo(io)
    return f
end



function select_ROI(f, test_frames = 50)
    #fps = Int(round(VideoIO.framerate(f)))
    Nframes = counttotalframes(f)

    ## Depending on video codec, above command may fail with ERROR: Could not send packet.
    ## Probably because it tries to continue after last frame instead of stopping properly.
    ## need encoding that is light, allow counttotalframes,
    ## and doesn't cut frames at start (last one not deal breaker).

    times = [] ##timestamps of each frame
    img = []

    seekstart(f)
    ### we load a small set of frames (here 2sec worth)
    ### in order to determine the coordinates of the ROI

    for i in ProgressBar(1 : test_frames)
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

    for i in ProgressBar(1 : Nframes)
        frame = read(f)
        cframe = frame[ROIcoords[:ylower]:ROIcoords[:yupper], ROIcoords[:xlower]:ROIcoords[:xupper]]
        push!(times, gettime(f))
        framemean = mean(cframe)
        push!(avgred, red(framemean))
        push!(avggreen, green(framemean))
        push!(avgblue, blue(framemean))
    end

    df = DataFrame(time = times, valueR = avgred, valueG = avggreen, valueB = avgblue)
    return df
end


function check_quality(df)
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

    wait(display(fig))
    return to_value(good_enough)
end

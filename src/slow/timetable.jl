

function unix2second(ts)
    dt = unix2datetime(ts)
end


function maketimetable(path::String)
    allfields = [:mtime, :user, :iter, :success, :error, :time]
    groupby = GroupBy([:mtime, :user, :success, :time],
                      groupers=[:mtime => unix2second,
                                :user => identity,
                                :success => identity])
    open(path) do f
        for line in eachline(f)
            (mtime, user, iter, success, error, time) = split(line, ',')
            if !bool(success)
                # TODO: parse :error and save error reasons with count
            end
            update!(groupby, [mtime, user, success, time])
        end
    end
    df = todataframe(groupby) # TODO
    # TODO: return one more dataframe for errors? 
end

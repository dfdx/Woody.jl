
todataframe(bufdump) =
    readtable(IOBuffer(bufdump), names=[:ts, :uid, :itr, :elapsed], header=false)




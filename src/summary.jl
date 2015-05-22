
todataframe(bufdump) =
    readtable(IOBuffer(bufdump), names=[:ts, :status, :uid, :itr, :elapsed], header=false)




(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using EmbedViewer
const UserApp = EmbedViewer
EmbedViewer.main()

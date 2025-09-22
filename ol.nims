--d:release
--app:gui
--out:OfLands.exe

while not fileExists("SDL2.dll"):
  raise newException(Exception, "No SDL2 file available")
--d:release
--threads:on # optional ig
--app:gui
--out:OfLands.exe

while not fileExists("SDL2.dll"):
  raise newException(Exception, "No SDL2 file available")

while not fileExists("SDL2_image.dll"):
  raise newException(Exception, "No SDL2_image file available")
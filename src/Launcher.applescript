on run
  set appPath to POSIX path of (path to me)
  set screenoffScript to appPath & "Contents/Resources/screenoff.sh"
  set quotedScript to quoted form of screenoffScript
  set quotedLaunchLog to quoted form of "/tmp/sleepycat-screen-off-launch.log"

  do shell script "/bin/echo \"$(/bin/date '+%Y-%m-%d %H:%M:%S') Launching fixed 8-hour display sleep script:\" " & quotedScript & " >> " & quotedLaunchLog & "; /bin/zsh " & quotedScript & " >> " & quotedLaunchLog & " 2>&1 &"
end run

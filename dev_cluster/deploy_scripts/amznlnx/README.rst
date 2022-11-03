A dev box to test out new code, run one-off dev scripts,
or test CloudFormation stacks.


##############################################################
Keeping the process alive after logging out of SSH session
##############################################################
Compare: "screen" or "tmux".
"tmux" is a modern alternative to "screen" and has some features that modern developers need. On the other hand, screen is much more stable (been around since 1987) and is available on pretty much all *Nix distros out of the box.
We don't need most of the extra features that tmux is offering, so we'll use "screen" to simplify.
https://superuser.com/questions/236158/tmux-vs-screen
https://askubuntu.com/questions/8653/how-to-keep-processes-running-after-ending-ssh-session


### to enable some features like logging, you need to have permission
$ sudo su

### to start a new screen and enable logging
# the logs will appear on your home directory
$ screen -LS <session_name>

### to attach to an existing screen
# Remember to sudo su if you had run screen inside sudo shell.
$ sudo su
# first get a list of all running screens and fetch the id of the screen you want to attach to
$ screen -ls
# attach to the running screen
$ screen -rd <screen_id or session_name>

### to detach from a running screen
$ ctrl+A d

### to kill an existing screen
# from inside the window (attached window)
$ ctrl+A K
# from outside the window (detached window)
$ screen -X -S 21929 quit

### Scroll up & down in screen
# Hit your screen prefix combination (C-a / control+A by default), then hit Escape
# Move up/down with the arrow keys (↑ and ↓).
# When you're done, hit q or Escape to get back to the end of the scroll buffer.


- Screen tutorials:
https://www.tecmint.com/screen-command-examples-to-manage-linux-terminals/
https://stackoverflow.com/questions/3202111/how-to-assign-name-for-a-screen
https://stackoverflow.com/questions/15026184/is-it-possible-to-name-the-screen-logfile-from-the-l-flag
https://serverfault.com/questions/248193/specifying-a-log-name-for-screen-output-without-relying-on-screenrc
https://unix.stackexchange.com/questions/40242/scroll-inside-screen-or-pause-output

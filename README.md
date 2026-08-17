JAZZLink is a script written in Lua within Reaper that allows you to extract the structure of a JJazzLab song as Reaper regions, and the chord names as markers in Reaper. 
You can then run Reaper while easily navigating the song’s structure, with the chord “grid” displayed right in front of you. JJazzLab music can be produced

 *either offline (by importing audio or MIDI exported from JJazzLab into Reaper)

 *or in sync (by running JJazzLab and Reaper simultaneously with (fairly) good synchronization of the start times and tempo between the two applications). For this “live” use of JJazzLab, J2JAZZLink utilizes the ability to remotely control navigation within a song via MIDI notes, a feature offered by JJazzLab 5.2.
 This allows you to use the Reaper environment to play with JJazzLab and, for example, record guitar or vocal parts “in sync” with JJazzLab.

 Installation

You need Reaper >= 7.72 and the ReaImgui library (see the Reaper website)
1) Place the J2JAZZLink.lua script in Reaper’s scripts folder.
2) Place the J2JJlatencyspy.jsfx plugin in Reaper’s effects folder (this plugin is used to estimate send latency when using JJazzLab “live”)
3) To complete the installation, launch Reaper and activate J2JAZZLink from Reaper’s Actions window (New Action, Load Reascript). It’s very useful to assign this script to an icon in the toolbar (Customize toolbar).

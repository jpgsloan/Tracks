# Tracks
iOS audio recording tool for quickly creating song demos.

STILL UNDER DEVELOPMENT, CORE FEATURES ALMOST COMPLETE!

Tracks gives musicians the power to quickly create, organize, and arrange their music recordings into songs. 
  - Import or record live audio into "track" nodes. 
  - Edit Track volumes and trim recordings.
  - Conncect track nodes together with links to play them simultaneously or sequentially.
  - Save song lyrics or notes about the recordings.
  - Use hand drawing, color-coordination, or dragging to organize tracks into groups.

Tracks is a stripped-down alternative to using Digital Audio Workstations geared towards quickly creating rough demos or beats. 
There is no timeline the way that traditional DAWs layout tracks. Links are used between tracks to
either trigger the next track when the current has completed or trigger several tracks simultaneously. 
There are also special tracks for "silence" that can be used when needed for timing. 

Many more features to come! 
 - midi support
 - audiobus / inter-app audio
 - input monitoring
 - export options
 - maybe audio effects one day.

IMPORTANT CLASSES:

Track - custom UIView for an individual Track. Contains code for recording audio, displaying relevant track data and waveforms, and track editing via long-press gesture recognizer.

ProjectViewController - custom UIViewController specific for an individual project. Contains code for adding new tracks, displaying notes, adding track links.

SelectProjectViewController - custom UIViewController for opening other projects or settings. Contains code for adding new projects, tableView of projects, and settings.

ProjectManagerViewController - custom UIViewController for facillitating transitions between SelectProjectVC and ProjectVC. Contains code for ViewController containment, opening selectProjVC as sidebar and opening projects when selected. 

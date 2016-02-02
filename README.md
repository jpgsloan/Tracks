# **Tracks Music**
iOS audio recording tool for quickly creating song demos.

Check out screenshots and video of the app on the [project webpage](http://jpgsloan.github.io/projects/tracks).

Tracks Music is currently in beta testing on TestFlight. If you want to become a beta tester, send your Apple ID email address to jpgsloan@gmail.com.

Tracks gives musicians the power to quickly create, organize, and arrange their music recordings into songs. 
  - Import or record live audio into "track" nodes. 
  - Edit Track volumes and trim recordings.
  - Connect track nodes together with links to play them simultaneously or sequentially.
  - Save song lyrics or notes about the recordings.
  - Use hand drawing, color-coordination, or dragging to organize tracks into groups.
  
Tracks is a stripped-down alternative to using a Digital Audio Workstation geared towards quickly creating rough demos or beats. 
There is no timeline the way that traditional DAWs layout tracks. Links are used between tracks to
either trigger the next track when the current has completed or trigger several tracks simultaneously. 

Many more features to come! 
 - midi support
 - audiobus / inter-app audio
 - audio effects
 - group editing for linked tracks
 - export options

**IMPORTANT CLASSES:**

**Track** - custom UIView for an individual Track. Contains code for recording/playing audio and displaying relevant track data and waveforms.

**ProjectViewController** - custom UIViewController specific for an individual project. Contains code for adding new tracks, displaying notes, switching tool mode (play, link, delete).

**SelectProjectViewController** - custom UIViewController for opening other projects or settings. Contains code for adding new projects, tableView of projects, and settings.

**ProjectManagerViewController** - custom UIViewController for facillitating transitions between SelectProjectVC and ProjectVC. Contains code for ViewController containment, opening selectProjVC as sidebar and opening projects when selected. 

**LinkManager** - custom UIView for facilitating the adding of track links as well as the deleting of links and tracks. It is the base view for ProjectViewController, and does some work to delegate touches appropriately. Basically the glue between links and tracks.

**TrackLink** - custom UIView that sits on top of n track nodes and plays through linked tracks starting at a given node and following the link edges (simultaneous or sequential) thereafter. Drag from one track to another in Add link mode to add a link.

**TrackEditView** - view for editing a track node. Added as subview when a track is long-pressed. In edit mode, it is possible to trim audio, adjust volumn/pan, change track node name and color. 

**WaveformEditView** - used as subview within TrackEditView to handle the waveform and audio trim portion of edit mode. 

**Original design mock-ups:**

![Alt text](/mockups.png?raw=true)

# Binspect

A Mac application by [Joe Savage](http://www.reinterpretcast.com/) for visualising binary data - inspired by the work of [Aldo Cortesi](http://corte.si/posts/visualisation/binvis/index.html), and to a lesser extent Greg Conti and Christopher Domas.

Currently the application is relatively bare-bones to its purpose, simply providing visualisation options via two space-filling curves and three colouring modes. The (slightly over-commented) code is licensed as described in the 'LICENSE' file, under the MIT license.

The application was developed on a Late 2013 Retina Macbook Pro running Yosemite. While I would hope it runs somewhat sensibly in other environments, I can make no guarantees to this effect.

![Binspect '/bin/ksh' screenshot](./screenshot.png?raw=true)

# Possible Improvements & Expansions
## Improvements
- Add a scrollbar, or indicate the scroll position to the user in some meaningful way
- Keyboard shortcuts for scrolling
- Sort out the 'Shannon Entropy' file statistic label - it varies too wildly based on file size and generally doesn't work well for larger inputs. Change the calculation to average the entropy of numerous blocks, remove the label entirely, or move the functionality to be a statistic of the hovered region.
- Hover-based locality zooming
- Improve 'hovered region'/'selection' functionality
	- Introduce a visual representation of the current selection
	- Selection locking
	- Selection nudging (with arrow keys?)
- Preferences window
	- Scroll sensitivity
	- Selection size
	- Entropy colouring mode block size
	- Default zoom level
- Handle dragging files directly onto the application window
- Properly handle 'Open With' functionality

## Expansions
- Dump data/selection to file
	- Similarly, opening the selection in a new window for analysis in isolation
- Save generated image
- Multiple documents windows
- Fullscreen mode (and window resizes)
- CLI alias ('binspect')
- Quick Look extension/generator

Other ideas (which I'm less sure about):
- Additional data visualisations/representations
	- Digraphs/trigraps of byte patterns (in the selection?) (diagram in sidebar?)
		- e.g. digraph of which byte values follow which other byte values
	- Selection auralisation
- Curve minimap navigation panel ('Sublime Text'-style minimap)
- Change selection functionality to be more intuitive than a region around the hovered byte
- Colour banding options (possibly makes things clearer sometimes than every different byte value having an individual colour)
- Byte grouping options (likely introduces alignment and endianness issues)
- Section labelling
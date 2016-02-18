
# Virtual Tourist
Virtual Tourist is an iOS app which display collection of photos taken around the world.

## Some of the technologies covered
Core Data
NSFetchedResultsControllerDelegate
NSURLSession / NSJSON
MapKit
CollectionView
Flickr API

## Challenges faced
Understanding how Core Data works
Using NSFetchedResultsController with MapKit and CollectionView
Understanding cycle of loading
Debugging data issue

## Possibles enhancements
Reduced loading times
Better UI
Implement drag and drop

## How to get started
1. Create a Key.plist at the root of your  folder
2. Add a string row named API_KEY
3. Enter the Value with you Flickr api key

You should end up with this code source:
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>YOURKEYHERE</string>
</dict>
</plist>
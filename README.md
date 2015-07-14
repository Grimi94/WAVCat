# WAVCat

WAV concat in iOS made simple

## Usage

Create instance with initial data

```swift
var audioPath = NSBundle.mainBundle().pathForResource("audio", ofType: "wav")!
var audioData = NSData(contentsOfFile: audioPath)!
var wavcat = WAVCat(data: audioData)
        
```

Now lets append some data

```swift
for i in 1...10 {
	wavcat!.append(otherAudioData)
}
```

To get the concatenated data just:

```swift
var finalAudioData = wavcat.getData()

```

From there you can save it, play it, send it, etc


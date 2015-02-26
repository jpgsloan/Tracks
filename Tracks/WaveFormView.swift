//
//  WaveFormView.swift
//  Tracks
//
//  Created by John Sloan on 2/15/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import AVFoundation

class WaveFormView: UIView {

    var audio: RecordedAudio!
    var extAudioFile: ExtAudioFileRef = nil
    var fileFormat: AudioStreamBasicDescription!
    var resultCode: OSStatus!
    var totalFrames: Int64!
    var totalDuration: Float64!
    var frameIndex: Int64 = 0
    
    var waveformData: UnsafeMutablePointer<Float>!
    var waveformFrameRate: UInt32!
    var waveformTotalBuffers: UInt32!
    var waveformResolution = 1024
    
    init (recordedAudio: RecordedAudio) {
        super.init()
        audio = recordedAudio
        createWaveForm(recordedAudio)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func createWaveForm(recordedAudio: RecordedAudio) {
        //open the file
        resultCode = ExtAudioFileOpenURL(recordedAudio.filePathUrl, &extAudioFile)
        
        //get the file format info
        var size = UInt32(sizeofValue(fileFormat))
        resultCode = ExtAudioFileGetProperty(extAudioFile, UInt32(kExtAudioFileProperty_FileDataFormat), &size, &fileFormat)
        println(fileFormat.mFormatID)
        
        //get duration and total frames of recording
        size = UInt32(sizeofValue(totalFrames))
        resultCode = ExtAudioFileGetProperty(extAudioFile, UInt32(kExtAudioFileProperty_FileLengthFrames), &size, &totalFrames)
        println(totalFrames)
        totalFrames = max(Int64(1), totalFrames)
        totalDuration = Float64(totalFrames) / Float64(fileFormat.mSampleRate)
        println(totalDuration)
    
        var clientFormat = EZAudio.monoFloatFormatWithSampleRate(Float(fileFormat.mSampleRate))
        
        waveformFrameRate = self.recommendedDrawingFrameRate()
        waveformTotalBuffers = self.minBuffersWithFrameRate(waveformFrameRate)
        waveformData = UnsafeMutablePointer<Float>.alloc(sizeof(Float) * Int(waveformTotalBuffers))
        
        for (var i: UInt32 = 0; i < waveformTotalBuffers; i++) {
            
            var bufferList: UnsafeMutablePointer<AudioBufferList> = EZAudio.audioBufferListWithNumberOfFrames(waveformFrameRate, numberOfChannels: clientFormat.mChannelsPerFrame, interleaved: true)
            
            var bufferSize: UInt32!
            var endOfFile: Bool!
            
            //read frames
            resultCode = ExtAudioFileRead(extAudioFile,
                &waveformFrameRate!,
                bufferList)
        
            bufferSize = bufferList[0].mBuffers.mDataByteSize/UInt32(sizeof(Float));
            bufferSize = max(UInt32(1), bufferSize);
            endOfFile = waveformFrameRate == 0;
            frameIndex = frameIndex + Int64(waveformFrameRate);
        
            var buffPt = UnsafeMutablePointer<Float>(bufferList[0].mBuffers.mData)
            
            var buffSize = CInt(bufferSize)
            
            var rms: Float = EZAudio.RMS(buffPt, length: buffSize)
            
            waveformData[Int(i)] = rms;
        }
        
        for (var i = 0; i < 100; i++) {
            println(waveformData[i])
        }
        println("who know whats beyond")
        
    }
    
    func minBuffersWithFrameRate (var frameRate: UInt32) -> UInt32 {
        if (frameRate <= 0) {
            frameRate = 1
        }
        var val =  UInt32(totalFrames) / frameRate + UInt32(1)
        return max(1,val)
    }
    
    func recommendedDrawingFrameRate () -> UInt32 {
        var val = UInt32(totalFrames) / UInt32(waveformResolution);
        return max(1, val);
    }
    
    /*func audioBufferListWithNumberOfFrames (frames: UInt32, channels: UInt32, interleaved: Bool) -> AudioBufferList {
        
        var outputBufferSize: UInt32 = 32 * frames
        var toMalloc = UInt(channels * UInt32(sizeof(Float)) * outputBufferSize)
        
        var audioBuffer = AudioBuffer(mNumberChannels: channels, mDataByteSize: channels * outputBufferSize, mData: malloc(toMalloc))
        
        var audioBufs: Array<AudioBuffer> = [audioBuffer]
        
        //var audioBufferList = AudioBufferList(mNumberBuffers: channels, mBuffers: [])
        var audioBufferList: AudioBufferList!
        audioBufferList.mNumberBuffers = channels
        for (var i:UInt32 = 0; i < audioBufferList.mNumberBuffers; i++) {
            audioBufferList.mBuffers[i].mNumberChannels = channels
        }
        
        return audioBufferList
    } */
    
    
    
    struct AudioBufferListSwift {
        var mNumberBuffers: UInt32
        var mBuffers: [AudioBuffer]
    }
    
    
    
    
    
}

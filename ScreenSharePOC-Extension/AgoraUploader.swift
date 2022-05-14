//
//  AgoraUploader.swift
//  ScreenSharePOC-Extension
//
//  Created by Anwesh M on 14/05/22.
//

import Foundation
import CoreMedia
import ReplayKit
import OSLog


class AgoraUploader {
    private static let videoDimension : CGSize = {
        let screenSize = UIScreen.main.currentMode!.size
        var boundingSize = CGSize(width: 720, height: 1280)
        let mW = boundingSize.width / screenSize.width
        let mH = boundingSize.height / screenSize.height
        if( mH < mW ) {
            boundingSize.width = boundingSize.height / screenSize.height * screenSize.width
        }
        else if( mW < mH ) {
            boundingSize.height = boundingSize.width / screenSize.width * screenSize.height
        }
        return boundingSize
    }()
    
    private static let audioSampleRate: UInt = 48000
    private static let audioChannels: UInt = 2
    
    private static let sharedAgoraEngine: AgoraRtcEngineKit = {
        let kit = AgoraRtcEngineKit.sharedEngine(withAppId: KeyCenter.AppId, delegate: nil)
        kit.setChannelProfile(.liveBroadcasting)
        kit.setClientRole(.broadcaster)
        
        kit.enableVideo()
        kit.setExternalVideoSource(true, useTexture: true, pushMode: true)
        let videoConfig = AgoraVideoEncoderConfiguration(size: videoDimension,
                                                         frameRate: .fps24,
                                                         bitrate: AgoraVideoBitrateStandard,
                                                         orientationMode: .adaptative)
        kit.setVideoEncoderConfiguration(videoConfig)
        
        kit.setAudioProfile(.musicStandardStereo, scenario: .default)
        AgoraAudioProcessing.registerAudioPreprocessing(kit)
        kit.setRecordingAudioFrameParametersWithSampleRate(Int(audioSampleRate),
                                                           channel: Int(audioChannels),
                                                           mode: .readWrite,
                                                           samplesPerCall: 1024)
        kit.setParameters("{\"che.audio.external_device\":true}")
        kit.setParameters("{\"che.hardware_encoding\":1}")
        kit.setParameters("{\"che.video.enc_auto_adjust\":0}")
        
        kit.muteAllRemoteVideoStreams(true)
        kit.muteAllRemoteAudioStreams(true)
        
        return kit
    }()
    
    static func startBroadcast(to channel: String) {
        os_log("ScreenSharePOC-Extension:: startBroadcast")
        sharedAgoraEngine.joinChannel(byToken: KeyCenter.Token, channelId: channel, info: nil, uid: 0) { s, u, i in
            os_log("ScreenSharePOC-Extension:: startBroadcast")
        }
    }
    
    static func sendVideoBuffer(_ sampleBuffer: CMSampleBuffer) {
        os_log("ScreenSharePOC-Extension:: sendVideoBuffer")
        guard let videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer)
             else {
            return
        }
        
        var rotation : Int32 = 0
        if let orientationAttachment = CMGetAttachment(sampleBuffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil) as? NSNumber {
            if let orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value) {
                switch orientation {
                case .up,    .upMirrored:    rotation = 0
                case .down,  .downMirrored:  rotation = 180
                case .left,  .leftMirrored:  rotation = 90
                case .right, .rightMirrored: rotation = 270
                default:   break
                }
            }
        }
        
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        let frame = AgoraVideoFrame()
        frame.format = 12
        frame.time = time
        frame.textureBuf = videoFrame
        frame.rotation = rotation
        sharedAgoraEngine.pushExternalVideoFrame(frame)
    }
    
    static func sendAudioAppBuffer(_ sampleBuffer: CMSampleBuffer) {
        AgoraAudioTube.agoraKit(sharedAgoraEngine,
                                pushAudioCMSampleBuffer: sampleBuffer,
                                resampleRate: audioSampleRate,
                                type: .app)
    }
    
    static func sendAudioMicBuffer(_ sampleBuffer: CMSampleBuffer) {
        AgoraAudioTube.agoraKit(sharedAgoraEngine,
                                pushAudioCMSampleBuffer: sampleBuffer,
                                resampleRate: audioSampleRate,
                                type: .mic)
    }
    
    static func stopBroadcast() {
        os_log("ScreenSharePOC-Extension:: stopBroadcast")
        sharedAgoraEngine.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
    }
}

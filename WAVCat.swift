//
//  WAVCat.swift
//
//
//  Created by Grimi on 7/10/15.
//
//

import UIKit
import Darwin

struct Header {
    var channels:Int
    var samplesPerSecond:Int
    var bytesPerSecond:Int
    var dataSize:Int
}

class WAVCat: NSObject {

    private var finalData:NSMutableData?
    private var initialData:NSData?
    private var headerBytes:[UInt8]?
    private var headerInfo:Header?

    init(url:NSURL){

    }

    /**
    Initialized WAVCat instance with the NSData of the first wav file, its headers will 
    be modified and used for the final data.

    :param: initialData NSData with contents of wav file
    */
    init(data:NSData) {
        super.init()
        self.initialData = data;
        self.extractHeaders()

    }

    /**
    Extracts the first 44 bytes of the initialData since WAV headers have this length
    */
    private final func extractHeaders(){
        if let data = self.initialData{
            let reference = UnsafePointer<UInt8>(data.bytes)

            // Count is 44 since wav headers are 44 bytes long
            let buffer = UnsafeBufferPointer<UInt8>(start:reference, count:44)
            let header = [UInt8](buffer)

            self.validate(header, withData: data)
        }
    }

    /**
    Validate that the headers extracted are indeed valid WAV headers and data has the correct size
    */
    private final func validate(header:[UInt8], withData data:NSData){
        // extract values for validation
        let fileDescription = header[0...3]
        let wavDescription = header[8...11]
        let formatDescription = header[12...14]
        let headerDataSize = header[40...41]

        let hexNumber = String(headerDataSize[1], radix: 16, uppercase: false) + String(headerDataSize[0], radix: 16, uppercase: false)

        let expectedSize = data.length - 44
        let dataSize = Int(strtoul(hexNumber, nil, 16))

        if let str = String(bytes: fileDescription+wavDescription+formatDescription, encoding: NSUTF8StringEncoding){

            // very simple way to validate
            if str == "RIFFWAVEfmt" && expectedSize == dataSize {

            }
        }

    }

    
}

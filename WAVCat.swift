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

    private var contentData:NSMutableData
    private var initialData:NSData?
    private var headerBytes:[UInt8]
    private var headerInfo:Header?

    override init(){
        self.contentData = NSMutableData()
        self.headerBytes = []
        super.init()
    }

    /**
    Initialized WAVCat instance with the NSData of the first wav file, its headers will 
    be modified and used for the final data.

    :param: initialData NSData with contents of wav file
    */
    convenience init(data:NSData) {
        self.init()
        self.initialData = data;
        if let header = self.validate(data){
            self.headerBytes = header
            self.contentData.appendData(extractData(data))
        }
    }

    /**
    Extracts the first 44 bytes of the initialData since WAV headers have this length
    
    :param: data NSData from where headers will be extracted

    :returns: Headers array
    */
    private final func extractHeaders(data:NSData) -> [UInt8] {
        let reference = UnsafePointer<UInt8>(data.bytes)

        // Count is 44 since wav headers are 44 bytes long
        let buffer = UnsafeBufferPointer<UInt8>(start:reference, count:44)
        let header = [UInt8](buffer)

        return header
    }

    private final func extractData(data:NSData) -> NSData {
        return data.subdataWithRange(NSMakeRange(44, data.length - 44))
    }

    /**
    Validate that the headers extracted are indeed valid WAV headers and data has the correct size.

    :param: data NSData that wants to be validated

    :returns: If data is valid then it will return the header data othwerwise nil
    */
    private final func validate(data:NSData) -> [UInt8]? {
        // extract values for validation
        let header            = extractHeaders(data)
        let fileDescription   = header[0...3]
        let fileSize          = header[4...7]
        let wavDescription    = header[8...11]
        let formatDescription = header[12...14]
        let headerDataSize    = header[40...43]
        var dataSize:UInt32   = 0

        for (index, byte) in enumerate(headerDataSize) {
            dataSize |= UInt32(byte) << UInt32(8 * index)
        }

        let expectedDataSize = data.length - 44 // 44 is the size of the header

        if let str = String(bytes: fileDescription+wavDescription+formatDescription, encoding: NSUTF8StringEncoding){

            // very simple way to validate
            if str == "RIFFWAVEfmt" && expectedDataSize == Int(dataSize) {

                // currently only data size is being used
//                self.headerInfo = Header(channels: 0, samplesPerSecond: 0, bytesPerSecond: 0, dataSize: dataSize)
                return header
            }
        }
        return nil
    }

    /**
    Append incomming data to the existing data and also adjusts header size

    :param: data WAV file data
    */
    final func append(data:NSData){
        if let header = validate(data){
            let dataSizeBytes    = header[40...43]
            let currentSizeBytes = headerBytes[40...43]

            var currentSize:UInt32 = 0
            var dataSize:UInt32    = 0

            for (index, byte) in enumerate(dataSizeBytes) {
                currentSize |= UInt32(byte) << UInt32(8 * index)
            }

            for (index, byte) in enumerate(currentSizeBytes) {
                dataSize |= UInt32(byte) << UInt32(8 * index)
            }

            let newSize = currentSize + dataSize
            

            headerBytes[43] = UInt8(newSize >> 24)
            headerBytes[42] = UInt8(newSize >> 16)
            headerBytes[41] = UInt8(newSize >> 8)
            headerBytes[40] = UInt8((newSize << 24) >> 24)  // UInt8(newSize) crashes...

            contentData.appendData(extractData(data))
            
        } else {
            // throw error
        }

    }

    /**
    Merges header data with the contentData

    :returns: Playable NSData
    */
    final func getData() -> NSData{
        let temp = NSMutableData()

        temp.appendData(NSData(bytes: &headerBytes, length: headerBytes.count))
        temp.appendData(contentData)

        return temp
    }

    
}

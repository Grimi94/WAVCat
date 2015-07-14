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
        let wavDescription    = header[8...11]
        let formatDescription = header[12...14]
        let headerDataSize    = header[40...41]

        let hexNumber    = String(headerDataSize[1], radix: 16, uppercase: false) + String(headerDataSize[0], radix: 16, uppercase: false)
        let expectedSize = data.length - 44
        let dataSize     = Int(strtoul(hexNumber, nil, 16))

        if let str = String(bytes: fileDescription+wavDescription+formatDescription, encoding: NSUTF8StringEncoding){

            // very simple way to validate
            if str == "RIFFWAVEfmt" && expectedSize == dataSize {

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
            let hexSizeCurrent = String(headerBytes[41], radix: 16, uppercase: false) + String(headerBytes[40], radix: 16, uppercase: false)
            let hexSizeData    = String(header[41], radix: 16, uppercase: false) + String(header[40], radix: 16, uppercase: false)
            let currentSize    = Int(strtoul(hexSizeCurrent, nil, 16))
            let dataSize       = Int(strtoul(hexSizeData, nil, 16))

            let newSize = currentSize + dataSize
            let hexSizenew = String(newSize, radix: 16, uppercase: false)
            let secondHalf = (hexSizenew as NSString).substringFromIndex(count(hexSizenew)-2)
            let firstHalf = (hexSizenew as NSString).substringToIndex((count(hexSizenew)/4)+1)

            headerBytes[41] = UInt8(strtoul(secondHalf, nil, 16))
            headerBytes[40] = UInt8(strtoul(firstHalf, nil, 16))

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

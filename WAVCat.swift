//
//  WAVCat.swift
//
//
//  Created by Grimi on 7/10/15.
//
//

import Foundation
import Darwin

struct Header {
    var channels:Int
    var samplesPerSecond:Int
    var bytesPerSecond:Int
    var dataSize:Int
}

class WAVCat: NSObject {

    private var contentData:Data
    private var initialData:Data?
    private var headerBytes:[UInt8]
    private var headerInfo:Header?

    override init(){
        self.contentData = Data()
        self.headerBytes = []
        super.init()
    }

    /**
    Initialized WAVCat instance with the Data of the first wav file, its headers will
    be modified and used for the final data.

    :param: initialData Data with contents of wav file
    */
    convenience init(_ data:Data) {
        self.init()
        self.initialData = data;
        if let header = self.validate(data){
            self.headerBytes = header
            self.contentData.append(extractData(data))
        }
    }

    /**
    Extracts the first 44 bytes of the initialData since WAV headers have this length

    :param: data Data from where headers will be extracted

    :returns: Headers array
    */
    private final func extractHeaders(_ data:Data) -> [UInt8] {
        // Count is 44 since wav headers are 44 bytes long
        return [UInt8](data.subdata(in: 0 ..< 44))
    }

    private final func extractData(_ data:Data) -> Data {
        return data.subdata(in: 44 ..< data.count)
    }

    /**
    Validate that the headers extracted are indeed valid WAV headers and data has the correct size.

    :param: data Data that wants to be validated

    :returns: If data is valid then it will return the header data othwerwise nil
    */
    private final func validate(_ data:Data) -> [UInt8]? {
        // extract values for validation
        let header            = extractHeaders(data)
        let fileDescription   = header[0...3]
//        let fileSize          = header[4...7]
        let wavDescription    = header[8...11]
        let formatDescription = header[12...14]
        let headerDataSize    = header[40...43]
        var dataSize:UInt32   = 0

        for (index, byte) in headerDataSize.enumerated() {
            dataSize |= UInt32(byte) << UInt32(8 * index)
        }

        let expectedDataSize = data.count - header.count

        if let str = String(bytes: fileDescription+wavDescription+formatDescription, encoding: String.Encoding.utf8){

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
    final func append(_ data:Data){
        if let header = validate(data){
            let dataSizeBytes    = header[40...43]
            let currentSizeBytes = headerBytes[40...43]

            var currentSize:UInt32 = 0
            var dataSize:UInt32    = 0

            for (index, byte) in dataSizeBytes.enumerated() {
                currentSize |= UInt32(byte) << UInt32(8 * index)
            }

            for (index, byte) in currentSizeBytes.enumerated() {
                dataSize |= UInt32(byte) << UInt32(8 * index)
            }

            let newSize = currentSize + dataSize
            let fileSize = newSize + 44 - 8

            headerBytes[7] = UInt8(truncatingIfNeeded: fileSize >> 24)
            headerBytes[6] = UInt8(truncatingIfNeeded: fileSize >> 16)
            headerBytes[5] = UInt8(truncatingIfNeeded: fileSize >> 8)
            headerBytes[4] = UInt8(truncatingIfNeeded: fileSize)

            headerBytes[43] = UInt8(truncatingIfNeeded: newSize >> 24)
            headerBytes[42] = UInt8(truncatingIfNeeded: newSize >> 16)
            headerBytes[41] = UInt8(truncatingIfNeeded: newSize >> 8)
            headerBytes[40] = UInt8(truncatingIfNeeded: newSize)


            contentData.append(extractData(data))

        } else {
            // throw error
        }

    }

    /**
    Merges header data with the contentData

    :returns: Playable Data
    */
    final func getData() -> Data{
        var temp = Data()

        temp.append(&headerBytes, count: headerBytes.count)
        temp.append(contentData)

        return temp
    }


}

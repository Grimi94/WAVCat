//
//  WAVCat.swift
//
//
//  Created by Grimi on 7/10/15.
//
//

import UIKit

class WAVCat: NSObject {

    private var finalData:NSMutableData?
    private var initialData:NSData?
    var headerBytes:[UInt8]?

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

    private final func extractHeaders(){
        if let data = self.initialData{

            let count = data.length / sizeof(UInt32)
            let reference = UnsafePointer<UInt8>(data.bytes)
            let buffer = UnsafeBufferPointer<UInt8>(start:reference, count:44)
            self.headerBytes = [UInt8](buffer)

        } else {

        }
    }

    
}

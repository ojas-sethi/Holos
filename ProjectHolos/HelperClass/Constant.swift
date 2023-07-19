//
//  Constant.swift
//  ProjectHolos
//
//  Created by Ojas Sethi on 20/01/19.
//  Copyright © 2019 Ojas Sethi. All rights reserved.
//

import Foundation
//  MARK: Constant Properties
let kWatsonBaseURL = "https://stream.watsonplatform.net/text-to-speech/api/v1/synthesize?"

//  MARK: Structures
struct kWatsonCredentials {
    static let username = "apikey"
    static let password = "XgOgT4_bqzh2UJsP_2JPewuIjdsTpR6M1ba5Rgwb358j" // The password is the API Key
    
}

//  MARK: Enums
enum kWatsonVoices: String {
    case michael = "en-US_MichaelVoice"
    case kate = "en-GB_KateVoice"
    case allison = "en-US_AllisonVoice"
    case lisa = "en-US_LisaVoice"
}

//  MARK: SAMPLES
//  WATSON REQUEST PATTERN: https://XgOgT4_bqzh2UJsP_2JPewuIjdsTpR6M1ba5Rgwb358j@stream.watsonplatform.net/text-to-speech/api/v1/synthesize?accept=audio/wav&voice=en-US_MichaelVoice&text=hello

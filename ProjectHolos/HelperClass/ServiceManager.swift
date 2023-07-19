//
//  ServiceManager.swift
//  ProjectHolos
//
//  Created by Ojas Sethi on 20/01/19.
//  Copyright © 2019 Ojas Sethi. All rights reserved.
//

import UIKit

class ServiceManager: NSObject {
    static let sharedInstance = ServiceManager()
    //  MARK: Private Properties
    private let defaultSession = URLSession(configuration: .default)
    private var dataTask: URLSessionDataTask!
    
    //  MARK: typealias
    typealias APIResponse = (Data?) -> ()
    
    //  MARK: Private Methods
    private func callWebService(url: URL, completion: @escaping APIResponse) {
        let username = kWatsonCredentials.username
        let password = kWatsonCredentials.password
        let loginString = String(format: "%@:%@", username, password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        
        // create the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        self.dataTask = defaultSession.dataTask(with: request, completionHandler: { (data, response, error) in
            defer { self.dataTask = nil }
            
            if let error = error {
                debugPrint("DataTask error: " + error.localizedDescription)
            } else if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                
                DispatchQueue.main.async {
                    completion(data)
                }
            }
        })
        
        self.dataTask.resume()
    }
    
    //  MARK: Methods
    func speakRequestFor(textValue: String, inVoice voice: kWatsonVoices, completion: @escaping APIResponse) {
        let baseURL = kWatsonBaseURL
        let ampersand = "&"
        let acceptTagAndValue = "accept=audio/wav"
        let voiceTagAndValue = "voice=\(voice.rawValue)"
        let textTagAndValue = "text=\(textValue)"
        
        let serviceURLString = baseURL + acceptTagAndValue + ampersand + voiceTagAndValue + ampersand + textTagAndValue
        
        if let serviceURL = URL(string: serviceURLString) {
            self.callWebService(url: serviceURL, completion: completion)
        }
    }
}

//
//  TokenData.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import Foundation

struct Token: Decodable {
    var application: String
    var owner: String
    var permit: String
    var purpose: String
    var token: String

    static let initial: Token = Token(application: "", owner: "", permit: "", purpose: "", token: "")
}

struct TokenDel: Decodable {
    var owner: String
    var token: String
}

extension Token {
    
    func newToken() async -> Token {
        var retVal = Token.initial
        var request: URLRequest
        if let url = URL(string: getURL(for: Endpoint.token)!) {
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("OVMSwatch", forHTTPHeaderField: "application")
            do {
                let ( data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 201 {
                        if let decodedResponse = try? JSONDecoder().decode(Token.self, from: data) {
                            retVal = decodedResponse
                            //print("Got token: \(retVal.token)")
                        }
                        return retVal
                    }
                }
                return retVal
            }
            catch {
                return retVal
            }
        }
        return retVal
    }
    
    func getToken() async {
        if let url = URL(string: getURL(for: Endpoint.token)!) {
            var value: [Token]
            var request: URLRequest
            request = URLRequest(url: url)
            request.httpMethod = "GET"
            do {
                let ( data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let decodedResponse = try? JSONDecoder().decode([Token].self, from: data) {
                            value = decodedResponse
                            // If there are no tokens available get a new one
                            if value.count == 0 {
                                currentToken = await newToken()
                                if await checkToken() {
                                    print("New Token: \(currentToken.token)")
                                } else {
                                    print("Bad token received")
                                }
                            }
                            // If there is only 1 token use it
                            if value.count == 1 {
                                if  let receivedToken = value.first {
                                    currentToken = receivedToken
                                    if await checkToken() {
                                        print("Reused Token: \(currentToken.token)")
                                    } else {
                                        print("Bad token received")
                                    }
                                }
                            } else {
                                // Otherwise delete all the tokens and get a new one
                                for tokenElement in value {
                                    //print("Token = \(tokenElement.token)")
                                    currentToken = tokenElement
                                    print("More than one token. Delete all")
                                    await delToken()
                                    currentToken = await newToken()
                                    if await checkToken() {
                                        print("Replacment Token: \(currentToken.token)")
                                    } else {
                                        print("Bad token received")
                                    }
                                }
                            }
                        }
                        return
                    }
                }
                return
            }
            catch {
                return
            }
        }
    }
    
    func delTokens() {
        if let url = URL(string: getURL(for: Endpoint.token)!) {
            Task {
                var value: [Token]
                var request: URLRequest
                request = URLRequest(url: url)
                request.httpMethod = "GET"
                do {
                    let ( data, response) = try await URLSession.shared.data(for: request)
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            if let decodedResponse = try? JSONDecoder().decode([Token].self, from: data) {
                                value = decodedResponse
                                for tokenElement in value {
                                    //print("Token = \(tokenElement.token)")
                                    currentToken = tokenElement
                                    await delToken()
                                }
                            }
                            return
                        }
                    }
                    return
                }
                catch {
                    return
                }
            }
        }
    }
    
    func delToken() async {
        var request: URLRequest
        if let url = URL(string: getURL(for: Endpoint.token)!) {
            request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            
            do {
                let ( data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let reply = try? JSONDecoder().decode(TokenDel.self, from: data) {
                            print("Deleted: \(reply.token)")
                        }
                    }
                }
            }
            catch {
                return
            }
        }
    }
    
    func checkToken() async -> Bool {
        var request: URLRequest
        if let url = URL(string: getURL(for: Endpoint.vehicles)!) {
            request = URLRequest(url: url)
            do {
                let ( data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return false }
                vehicles = try JSONDecoder().decode([Vehicle].self, from: data)
                return true
            }
            catch {
                print("(Check Token) FAILED")
                return false
            }
        }
        print("(Check Token) FAILED")
        return false
    }
}

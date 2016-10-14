//
//  WikipediaLanguages.swift
//  AnyPOI
//
//  Created by Sébastien Brugalières on 09/10/2016.
//  Copyright © 2016 Sébastien Brugalières. All rights reserved.
//

import Foundation

class WikipediaLanguages {
    //Key is ISO language code and value is the start for Wikipedia URL
    //All Languages with 100 0000+ Articles
    static let languageCodeToStartEndPoint = [ "en":"en",
                                               "fr":"fr",
                                               "sv":"sv",
                                               "ceb":"ceb",
                                               "de":"de",
                                               "nl":"nl",
                                               "ru":"ru",
                                               "it":"it",
                                               "es":"es",
                                               "war":"war",
                                               "pl":"pl",
                                               "vi":"vi",
                                               "ja":"ja",
                                               "pt":"pt",
                                               "zh":"zh",
                                               "uk":"uk",
                                               "ca":"ca",
                                               "fa":"fa",
                                               "no":"no",
                                               "ar":"ar",
                                               "sh":"sh",
                                               "fi":"fi",
                                               "hu":"hu",
                                               "id":"id",
                                               "ro":"ro",
                                               "cs":"cs",
                                               "ko":"ko",
                                               "sr":"sr",
                                               "ms":"ms",
                                               "tr":"tr",
                                               "eu":"eu",
                                               "eo":"eo",
                                               "min":"min",
                                               "bg":"bg",
                                               "da":"da",
                                               "kk":"kk",
                                               "sk":"sk",
                                               "hy":"hy",
                                               "zh-min-nan":"zh-min-nan",
                                               "he":"he",
                                               "lt":"lt",
                                               "hr":"hr",
                                               "sl":"sl",
                                               "ce":"ce",
                                               "et":"et",
                                               "gl":"gl",
                                               "nn":"nn",
                                               "uz":"uz",
                                               "la":"la",
                                               "el":"el",
                                               "be":"be",
                                               "simple":"simple",
                                               "vo":"vo",
                                               "th":"th",
                                               "hi":"hi",
                                               "az":"az",
                                               "ur":"ur",
                                               "ka":"ka"]
    
    static let defaultWikipediaLanguageISOcode = "en"

    // Convert Language ISO code to full language name
    fileprivate static let languageISOcodeToLanguage : [String:String] = {
        var result = [String:String]()
        
        for currentLanguageCode in languageCodeToStartEndPoint.keys {
            if let currentLanguage =  (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: currentLanguageCode) {
                result[currentLanguageCode] = currentLanguage
            }
        }
        return result
    }()
    
    // Convert Language name to ISO code
    fileprivate static let languageToLanguageISOcode : [String:String] = {
        var result = [String:String]()
        
        for currentLanguageCode in languageCodeToStartEndPoint.keys {
            if let currentLanguage =  (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: currentLanguageCode) {
                result[currentLanguage] = currentLanguageCode
            }
        }
        return result
    }()
    
    // Get All supported Languages
    static let supportedLanguages: [String] = {
        var result = [String]()
        
        for currentLanguageCode in languageCodeToStartEndPoint.keys {
            if let language =  (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: currentLanguageCode) {
                result.append(language)
            }
        }
        
        return result.sorted()
    }()
    
    // Return true if the language ISO code is available in Wikipedia
    static func hasISOCodeLanguage(_ languageISOcode:String) -> Bool {
        if let _ = languageCodeToStartEndPoint[languageISOcode] {
            return true
        } else {
            return false
        }
    }
    
    // Return Language ISO code for a Language (or the default one if the requested language doesn't exist)
    static func languageISOCodeForLanguage(_ language:String) -> String {
        return languageToLanguageISOcode[language] ?? defaultWikipediaLanguageISOcode
    }
    
    // Return the Language for the ISO code
    static func LanguageForISOcode(_ languageISOcode:String) -> String {
        return languageISOcodeToLanguage[languageISOcode] ?? "Unknown language"
    }
    
    // Return the Wikipedia endPoint based on the Wikipedia language configured in UserPrefs
    static func endPoint() -> String {
        return languageCodeToStartEndPoint[UserPreferences.sharedInstance.wikipediaLanguageISOcode] ?? defaultWikipediaLanguageISOcode
    }
}

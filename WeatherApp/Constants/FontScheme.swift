//
//  FontScheme.swift
//  WeatherApp
//
import Foundation
import SwiftUI

class FontScheme: NSObject {
    static func kAvenirBlack(size: CGFloat) -> Font {
        return Font.custom(FontConstant.kAvenirBlack, size: size)
    }

    static func kAvenirRoman(size: CGFloat) -> Font {
        return Font.custom(FontConstant.kAvenirRoman, size: size)
    }

    static func kAvenirLight(size: CGFloat) -> Font {
        return Font.custom(FontConstant.kAvenirLight, size: size)
    }

    static func kAvenirHeavy(size: CGFloat) -> Font {
        return Font.custom(FontConstant.kAvenirHeavy, size: size)
    }

    static func kAvenirBook(size: CGFloat) -> Font {
        return Font.custom(FontConstant.kAvenirBook, size: size)
    }

    static func kAvenirMedium(size: CGFloat) -> Font {
        return Font.custom(FontConstant.kAvenirMedium, size: size)
    }

    static func kNewYorkLargeRegular(size: CGFloat) -> Font {
        return Font.custom(FontConstant.kNewYorkLargeRegular, size: size)
    }

    static func fontFromConstant(fontName: String, size: CGFloat) -> Font {
        var result = Font.system(size: size)

        switch fontName {
        case "kAvenirBlack":
            result = self.kAvenirBlack(size: size)
        case "kAvenirRoman":
            result = self.kAvenirRoman(size: size)
        case "kAvenirLight":
            result = self.kAvenirLight(size: size)
        case "kAvenirHeavy":
            result = self.kAvenirHeavy(size: size)
        case "kAvenirBook":
            result = self.kAvenirBook(size: size)
        case "kAvenirMedium":
            result = self.kAvenirMedium(size: size)
        case "kNewYorkLargeRegular":
            result = self.kNewYorkLargeRegular(size: size)
        default:
            result = self.kAvenirBlack(size: size)
        }
        return result
    }

    enum FontConstant {
        /**
         * Please Add this fonts Manually
         */
        static let kAvenirBlack: String = "Avenir-Black"
        /**
         * Please Add this fonts Manually
         */
        static let kAvenirRoman: String = "Avenir-Roman"
        /**
         * Please Add this fonts Manually
         */
        static let kAvenirLight: String = "Avenir-Light"
        /**
         * Please Add this fonts Manually
         */
        static let kAvenirHeavy: String = "Avenir-Heavy"
        /**
         * Please Add this fonts Manually
         */
        static let kAvenirBook: String = "Avenir-Book"
        /**
         * Please Add this fonts Manually
         */
        static let kAvenirMedium: String = "Avenir-Medium"
        /**
         * Please Add this fonts Manually
         */
        static let kNewYorkLargeRegular: String = "NewYorkLarge-Regular"
    }
}

import SwiftUI

extension Color {
    static let sojourYellow = Color(red: 255/255, green: 204/255, blue: 0/255)
    static let sojourDarkGray = Color(red: 54/255, green: 54/255, blue: 54/255)
    
    static var background: Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? .black : .white
        })
    }
    
    static var foreground: Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? .white : .black
        })
    }
    
    static var accent: Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(Color.sojourYellow) : .black
        })
    }
    
    static var cardBorder: Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 1.0) :
                UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1.0)
        })
    }
    
    static var buttonBackground: Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(Color.sojourYellow) : .black
        })
    }
    
    static var buttonText: Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                .black : .white
        })
    }
    
    static var selectedOption: Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(Color.sojourYellow) : UIColor.systemGray5
        })
    }
    
    static var cardBackground: Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 40/255, green: 40/255, blue: 40/255, alpha: 1.0) : .white
        })
    }
    
    static var cardText: Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? .white : .black
        })
    }
    
    static var modalBackground: Color {
        return Color.black
    }
    
    static var modalText: Color {
        return Color.white
    }
    
    static var modalAccent: Color {
        return Color.sojourYellow
    }
    
    static var tabBackground: Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1.0) : 
                UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
        })
    }
    
    static var selectedTabBackground: Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(red: 60/255, green: 60/255, blue: 60/255, alpha: 1.0) : 
                UIColor.white
        })
    }
} 
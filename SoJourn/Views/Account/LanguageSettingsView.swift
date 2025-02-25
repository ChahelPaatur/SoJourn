import SwiftUI

struct LanguageSettingsView: View {
    @State private var selectedLanguage = "English"
    let languages = ["English", "Spanish", "French", "German", "Italian", "Japanese", "Korean", "Chinese"]
    
    var body: some View {
        List {
            ForEach(languages, id: \.self) { language in
                Button {
                    selectedLanguage = language
                } label: {
                    HStack {
                        Text(language)
                        Spacer()
                        if language == selectedLanguage {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Language")
    }
} 
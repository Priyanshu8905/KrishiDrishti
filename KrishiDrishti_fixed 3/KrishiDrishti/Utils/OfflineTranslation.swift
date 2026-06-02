// Utils/OfflineTranslation.swift
// KrishiDrishti — On-device translation using Apple's new Translation framework foundation models

import SwiftUI
#if canImport(Translation)
import Translation
#endif

extension View {
    @ViewBuilder
    func offlineTranslation(isPresented: Binding<Bool>, text: String) -> some View {
        #if canImport(Translation)
        if #available(iOS 18.0, *) {
            self.translationPresentation(isPresented: isPresented, text: text)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

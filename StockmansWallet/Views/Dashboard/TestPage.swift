//
//  TestPage.swift
//  StockmansWallet
//
//  Created by Leon Ernst on 5/1/2026.
//

import SwiftUI

struct TestPage: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Hello, Luke")
                .font(.title)
                .padding(.bottom, 20)
            
            // Button 1: Angus cattle breed
            Button("Angus") {
                print("DEBUG: Angus button tapped")
            }
            .buttonStyle(.borderedProminent)
            
            // Button 2: Hereford cattle breed
            Button("Hereford") {
                print("DEBUG: Hereford button tapped")
            }
            .buttonStyle(.borderedProminent)
            
            // Button 3: Brahman cattle breed
            Button("Brahman") {
                print("DEBUG: Brahman button tapped")
            }
            .buttonStyle(.borderedProminent)
            
            // Button 4: Charolais cattle breed
            Button("Charolais") {
                print("DEBUG: Charolais button tapped")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    TestPage()
}

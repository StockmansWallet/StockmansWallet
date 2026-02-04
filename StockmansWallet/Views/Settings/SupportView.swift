import SwiftUI
import MessageUI

// Debug: Help & Support view with nested legal documents and beta feedback
struct SupportView: View {
    @State private var showingMailCompose = false
    @State private var showingMailError = false
    
    var body: some View {
        List {
            // Debug: Beta testing feedback section - prominent for testers
            if Config.environment != .production {
                Section {
                    Button {
                        HapticManager.tap()
                        if MailHelper.canSendMail {
                            showingMailCompose = true
                        } else {
                            showingMailError = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .foregroundStyle(Theme.accentColor)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Report Issue")
                                    .font(Theme.headline)
                                    .foregroundStyle(Theme.primaryText)
                                Text("Send feedback about bugs or problems")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Beta Testing")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.secondaryText.opacity(0.7))
                        .textCase(.uppercase)
                }
                .listRowBackground(Theme.cardBackground)
            }
            
            Section("Contact") {
                Link(destination: URL(string: "mailto:support@stockmanswallet.com.au")!) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(Theme.accentColor)
                            .frame(width: 28)
                        Text("Email Support")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            .listRowBackground(Theme.cardBackground)
            
            // Debug: Legal documents section nested within Help & Support
            Section("Legal") {
                NavigationLink(destination: PrivacyPolicyView()) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                
                NavigationLink(destination: TermsOfServiceView()) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundGradient)
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingMailCompose) {
            MailComposeView(
                recipients: ["feedback@stockmanswallet.com.au"],
                subject: "Stockman's Wallet \(Config.environment.displayName) - Issue Report",
                body: MailHelper.betaFeedbackTemplate()
            )
        }
        .alert("Cannot Send Email", isPresented: $showingMailError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please set up an email account in Settings to send feedback.")
        }
    }
}

// MARK: - Mail Helper

/// Debug: Helper for composing emails with device info
enum MailHelper {
    /// Check if device can send mail
    static var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }
    
    /// Debug: Pre-filled template for beta feedback with device info
    static func betaFeedbackTemplate() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "Unknown"
        let iosVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        let deviceName = UIDevice.current.name
        let environment = Config.environment.shouldShowBadge ? Config.environment.displayName : "Production"
        
        return """
        
        
        --- Please describe the issue above this line ---
        
        
        
        ═══════════════════════════
        Device Information
        (Please keep this - it helps us debug!)
        ═══════════════════════════
        
        App Version: \(version) (\(build))
        Environment: \(environment)
        iOS Version: \(iosVersion)
        Device: \(deviceModel)
        Device Name: \(deviceName)
        
        """
    }
}

// MARK: - Mail Compose View

/// Debug: SwiftUI wrapper for MFMailComposeViewController
struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients(recipients)
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            // Debug: Log result for development
            switch result {
            case .sent:
                print("✅ Feedback email sent successfully")
            case .saved:
                print("📝 Feedback email saved as draft")
            case .cancelled:
                print("❌ Feedback email cancelled")
            case .failed:
                print("⚠️ Feedback email failed: \(error?.localizedDescription ?? "Unknown error")")
            @unknown default:
                print("❓ Unknown mail result")
            }
            
            dismiss()
        }
    }
}

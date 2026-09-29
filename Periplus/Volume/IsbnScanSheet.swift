import AVFoundation
import SwiftUI

/// ISBN capture. The button that proceeds to the system dialog says Continue.
struct IsbnScanSheet: View {
    var onCode: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var capture = IsbnCapture()
    @State private var armed = false
    @State private var typed = ""
    @State private var typedNote: String?
    @FocusState private var typing: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: RouteMeasure.pad) {
                        Text("Point the camera at the ISBN barcode, or type the digits.")
                            .font(RouteMeasure.mono(.body))
                            .foregroundStyle(DesignTokens.ink)
                            .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                        if capture.denied {
                            Text("The camera is off. You can still type the ISBN, or open Settings to change camera access.")
                                .font(RouteMeasure.mono(.caption))
                                .foregroundStyle(DesignTokens.muted)
                                .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(RoutePrimaryStyle())
                        } else if armed {
                            IsbnPreview(session: capture.session)
                                .frame(maxWidth: .infinity, minHeight: RouteMeasure.unit * 30)
                                .hairlinePlate()
                                .overlay {
                                    RoundedRectangle(cornerRadius: RouteMeasure.chip)
                                        .strokeBorder(DesignTokens.accent, lineWidth: RouteMeasure.hairline)
                                        .padding(RouteMeasure.band)
                                        .accessibilityHidden(true)
                                }
                        } else {
                            Text("The next step asks the system for the camera.")
                                .font(RouteMeasure.mono(.caption))
                                .foregroundStyle(DesignTokens.muted)
                                .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                            Button("Continue") {
                                armed = true
                                Task { await capture.start() }
                            }
                            .buttonStyle(RoutePrimaryStyle())
                        }
                        TextField("ISBN digits", text: $typed)
                            .keyboardType(.numberPad)
                            .font(RouteMeasure.mono(.body))
                            .foregroundStyle(DesignTokens.ink)
                            .padding(RouteMeasure.row)
                            .frame(minHeight: 44)
                            .hairlinePlate(radius: RouteMeasure.chip)
                            .focused($typing)
                            .onChange(of: typed) { _, value in
                                let cleaned = value.filter { $0.isNumber || $0 == "-" || $0 == " " }
                                if cleaned != value { typed = cleaned }
                            }
                        if let typedNote {
                            Text(typedNote)
                                .font(RouteMeasure.mono(.caption))
                                .foregroundStyle(DesignTokens.ink)
                        }
                        Button("Use these digits") { submitTyped() }
                            .buttonStyle(RouteQuietStyle())
                            .disabled(IsbnCapture.longestRun(in: typed).count < 8)
                        #if targetEnvironment(simulator)
                        Text("Simulator samples")
                            .font(RouteMeasure.mono(.micro))
                            .foregroundStyle(DesignTokens.muted)
                        Button("Use 9780141439518") { finish("9780141439518") }
                            .buttonStyle(RouteQuietStyle())
                        Button("Use 9780000000002") { finish("9780000000002") }
                            .buttonStyle(RouteQuietStyle())
                        #endif
                    }
                    .padding(RouteMeasure.band)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("ISBN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(RouteMeasure.mono(.body))
                        .frame(minHeight: 44)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { typing = false }
                }
            }
        }
        .onChange(of: capture.code) { _, code in
            guard let code else { return }
            finish(code)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { capture.stop() }
        }
        .onDisappear { capture.stop() }
    }

    private func submitTyped() {
        let run = IsbnCapture.longestRun(in: typed)
        guard (8...14).contains(run.count) else {
            typedNote = "Enter 8 to 14 digits from the ISBN."
            return
        }
        typedNote = nil
        finish(run)
    }

    private func finish(_ code: String) {
        capture.stop()
        onCode(code)
        dismiss()
    }
}

struct IsbnPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewHost {
        let view = PreviewHost()
        view.preview.session = session
        view.preview.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewHost, context: Context) {}

    final class PreviewHost: UIView {
        let preview = AVCaptureVideoPreviewLayer()
        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.addSublayer(preview)
        }
        required init?(coder: NSCoder) { nil }
        override func layoutSubviews() {
            super.layoutSubviews()
            preview.frame = bounds
        }
    }
}

@MainActor
@Observable
final class IsbnCapture: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    var code: String?
    var denied = false

    func start() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configure()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                configure()
            } else {
                denied = true
            }
        default:
            denied = true
        }
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
    }

    private func configure() {
        session.beginConfiguration()
        session.sessionPreset = .high
        if session.inputs.isEmpty, let device = AVCaptureDevice.default(for: .video) {
            if let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) {
                session.addInput(input)
            }
        }
        if session.outputs.isEmpty {
            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: .main)
                let wanted: [AVMetadataObject.ObjectType] = [.ean13, .ean8, .qr, .code128]
                output.metadataObjectTypes = wanted.filter { output.availableMetadataObjectTypes.contains($0) }
            }
        }
        session.commitConfiguration()
        if !session.isRunning { session.startRunning() }
    }

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        for object in metadataObjects {
            guard let readable = object as? AVMetadataMachineReadableCodeObject,
                  let raw = readable.stringValue else { continue }
            let run = IsbnCapture.longestRun(in: raw)
            if (8...14).contains(run.count) {
                let found = run
                MainActor.assumeIsolated {
                    self.code = found
                    self.stop()
                }
                return
            }
        }
    }

    /// Longest digit run in a barcode or URL, 8 to 14 digits. A 12 digit UPC-A gains a leading zero.
    nonisolated static func longestRun(in raw: String) -> String {
        var best = ""
        var current = ""
        for character in raw {
            if character.isNumber {
                current.append(character)
                if current.count > best.count { best = current }
            } else {
                current = ""
            }
        }
        if best.count == 12 {
            return "0" + best
        }
        if best.count > 14 {
            return String(best.prefix(14))
        }
        return best
    }
}

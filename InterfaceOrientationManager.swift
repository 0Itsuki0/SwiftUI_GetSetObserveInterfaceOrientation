
import SwiftUI
import Combine

@Observable
class InterfaceOrientationManager {
    var interfaceOrientation: UIInterfaceOrientation = .unknown
    var isInterfaceOrientationLocked: Bool = false
    
    var supportedOrientation: [UIInterfaceOrientation] = []
    
    var error: Error? = nil {
        didSet {
            if let error = self.error {
                print(error)
            }
        }
    }
    
    private var cancellable: AnyCancellable?
    private let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene

    init() {
        self.cancellable = windowScene?.publisher(for: \.effectiveGeometry)
            .sink(receiveValue: { geometry in
                self.isInterfaceOrientationLocked = geometry.isInterfaceOrientationLocked
                self.interfaceOrientation = geometry.interfaceOrientation
            })
       
        self.supportedOrientation = windowScene?.keyWindow?.rootViewController?.supportedInterfaceOrientations.interfaceOrientation ?? [windowScene?.effectiveGeometry.interfaceOrientation ?? .portrait]
        
    }
    
    deinit {
        self.cancellable?.cancel()
    }
    
    func setInterfaceOrientation(_ orientation: UIInterfaceOrientation) {
        guard orientation != self.interfaceOrientation else { return }
        let geometryPreference = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation.interfaceOrientationMask)
        windowScene?.requestGeometryUpdate(geometryPreference, errorHandler: { error in
            self.error = error
        })
    }
    
}


struct InterfaceOrientationDemo: View {

    @State private var interfaceOrientationManager = InterfaceOrientationManager()
    @State private var orientation: UIInterfaceOrientation = .portrait
        
    var body: some View {
        NavigationStack {
            List {
                Section("Current Value") {
                    let interfaceOrientation = interfaceOrientationManager.interfaceOrientation
                    let isInterfaceOrientationLocked = interfaceOrientationManager.isInterfaceOrientationLocked
                    
                    HStack {
                        Text("Interface Orientation")
                        Spacer()
                        Text(interfaceOrientation.displayString)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Orientation Locked")
                        Spacer()
                        Text(String(isInterfaceOrientationLocked))
                            .foregroundStyle(.secondary)
                    }
                }
                
                
                Section("Set Value") {
                    HStack {
                        Text("Interface Orientation")
                        
                        Spacer()

                        Picker(selection: $orientation, content: {
                            ForEach(interfaceOrientationManager.supportedOrientation, id: \.rawValue, content: { orientation in
                                Text(orientation.displayString)
                                    .tag(orientation)
                            })
                        }, label: { })
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .onChange(of: self.orientation, {
                            self.interfaceOrientationManager.setInterfaceOrientation(self.orientation)
                        })
                        .onChange(of: self.interfaceOrientationManager.interfaceOrientation, {
                            if self.interfaceOrientationManager.interfaceOrientation != self.orientation{
                                self.orientation = self.interfaceOrientationManager.interfaceOrientation
                            }
                        })

                    }

                }

            }
            .contentMargins(.top, 8)
            .navigationTitle("Interface Orientation")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}



extension UIInterfaceOrientation {
    var displayString: String {
        switch self {
            
        case .unknown:
            "Unknown"
        case .portrait:
            "Portrait"
        case .portraitUpsideDown:
            "Portrait Upside Down"
        case .landscapeLeft:
            "Landscape Left"
        case .landscapeRight:
            "Landscape Right"
        @unknown default:
            "Unknown"
        }
    }
    
    var interfaceOrientationMask: UIInterfaceOrientationMask {
        switch self {
        case .unknown:
                .all
        case .portrait:
                .portrait
        case .portraitUpsideDown:
                .portraitUpsideDown
        case .landscapeLeft:
                .landscapeLeft
        case .landscapeRight:
                .landscapeRight
        @unknown default:
                .all
        }
    }
}


extension UIInterfaceOrientationMask {
    // NOTE:
    // Even if supportedInterfaceOrientations on the root view controller is set to UIInterfaceOrientationMask.all, we will still get the following error while trying to set to `portraitUpsideDown`
    // Error Domain=UISceneErrorDomain Code=101 "None of the requested orientations are supported by the view controller. Requested: portraitUpsideDown; Supported: portrait, landscapeLeft, landscapeRight" UserInfo={NSLocalizedDescription=None of the requested orientations are supported by the view controller. Requested: portraitUpsideDown; Supported: portrait, landscapeLeft, landscapeRight}
    var interfaceOrientation: [UIInterfaceOrientation] {
        switch self {
        case .all:
            [.portrait, .landscapeLeft, .landscapeRight]
        case .portrait:
            [.portrait]
        case .allButUpsideDown:
            [.portrait, .landscapeLeft, .landscapeRight]
        case .landscape:
            [.landscapeLeft, .landscapeRight]
        case .landscapeLeft:
            [.landscapeLeft]
        case .landscapeRight:
            [.landscapeRight]
        default:
            [.portrait, .landscapeLeft, .landscapeRight]
        }
    }
}

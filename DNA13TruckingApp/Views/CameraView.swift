import SwiftUI
import AVFoundation

// MARK: - Camera View for Image Capture
struct CameraView: UIViewControllerRepresentable {
    let onImageCapture: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCapture: onImageCapture)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCapture: (UIImage) -> Void
        
        init(onImageCapture: @escaping (UIImage) -> Void) {
            self.onImageCapture = onImageCapture
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageCapture(image)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Document Scanner View using VisionKit
struct DocumentScannerView: UIViewControllerRepresentable {
    let onScanningResult: (String) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Note: This is a simplified version. In a real app, you would use
        // DataScannerViewController from VisionKit for document scanning
        let viewController = UIViewController()
        viewController.view.backgroundColor = .black
        
        // Add a placeholder interface
        let label = UILabel()
        label.text = "VisionKit Document Scanner\n(Simulated View)"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        
        viewController.view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 40),
            label.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -40)
        ])
        
        // Add cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancelar", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        cancelButton.addTarget(context.coordinator, action: #selector(Coordinator.cancel), for: .touchUpInside)
        
        viewController.view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor, constant: -40)
        ])
        
        // Add simulate capture button
        let simulateButton = UIButton(type: .system)
        simulateButton.setTitle("Simular Escaneo", for: .normal)
        simulateButton.setTitleColor(.black, for: .normal)
        simulateButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        simulateButton.backgroundColor = .orange
        simulateButton.layer.cornerRadius = 8
        simulateButton.addTarget(context.coordinator, action: #selector(Coordinator.simulateScan), for: .touchUpInside)
        
        viewController.view.addSubview(simulateButton)
        simulateButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            simulateButton.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            simulateButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -20),
            simulateButton.widthAnchor.constraint(equalToConstant: 200),
            simulateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScanningResult: onScanningResult, onCancel: onCancel)
    }
    
    class Coordinator: NSObject {
        let onScanningResult: (String) -> Void
        let onCancel: () -> Void
        
        init(onScanningResult: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.onScanningResult = onScanningResult
            self.onCancel = onCancel
        }
        
        @objc func cancel() {
            onCancel()
        }
        
        @objc func simulateScan() {
            // Simulate OCR result
            let mockText = """
            BOL #12345
            Shipper: ABC Corporation
            Consignee: XYZ Logistics
            Weight: 42,000 lbs
            Pieces: 24
            Commodity: Electronics
            Pickup: Atlanta, GA
            Delivery: Miami, FL
            """
            onScanningResult(mockText)
        }
    }
}

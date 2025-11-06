import SwiftUI
import VisionKit
import AVFoundation

// MARK: - Document Scan View
struct DocumentScanView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appState: AppState
    @State private var showingScanner = false
    @State private var selectedDocumentType: DocumentType = .bol
    @State private var scannedText = ""
    @State private var isProcessing = false
    @State private var processingResult: OCRResponse?
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    
    private let documentTypes = DocumentType.allCases
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.dnaBackground, .dnaGreenDark.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Document Type Selection
                        documentTypeSelectionView
                        
                        // Scanner Actions
                        scannerActionsView
                        
                        // Camera Preview
                        if let image = capturedImage {
                            cameraPreviewView(image)
                        }
                        
                        // Scanned Text Results
                        if !scannedText.isEmpty {
                            scannedTextView
                        }
                        
                        // Processing Results
                        if let result = processingResult {
                            processingResultsView(result)
                        }
                        
                        // Recent Scanned Documents
                        recentDocumentsView
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Escanear Documentos")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(
                    onImageCapture: { image in
                        capturedImage = image
                        showingCamera = false
                        processImage(image)
                    }
                )
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView(
                    onScanningResult: { text in
                        scannedText = text
                        showingScanner = false
                        processText(text)
                    },
                    onCancel: {
                        showingScanner = false
                    }
                )
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(.dnaOrange)
            
            Text("Escaneo Inteligente de Documentos")
                .font(Typography.h2)
                .foregroundColor(.dnaTextSecondary)
                .multilineTextAlignment(.center)
            
            Text("Escanea BOL, facturas, contratos y permisos con OCR integrado")
                .font(Typography.body)
                .foregroundColor(.dnaTextSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Document Type Selection View
    private var documentTypeSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tipo de Documento")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(documentTypes, id: \.self) { type in
                        DocumentTypeButton(
                            type: type,
                            isSelected: selectedDocumentType == type
                        ) {
                            selectedDocumentType = type
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Scanner Actions View
    private var scannerActionsView: some View {
        VStack(spacing: 16) {
            // Native VisionKit Scanner
            Button(action: { showingScanner = true }) {
                HStack {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Escáner Nativo")
                            .font(Typography.button)
                            .foregroundColor(.dnaBackground)
                        
                        Text("Escaneo automático de documentos")
                            .font(Typography.caption)
                            .foregroundColor(.dnaBackground.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .dnaBackground))
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16))
                            .foregroundColor(.dnaBackground.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.dnaOrange)
                .cornerRadius(12)
            }
            .disabled(isProcessing)
            
            // Camera Capture
            Button(action: { showingCamera = true }) {
                HStack {
                    Image(systemName: "camera")
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Capturar con Cámara")
                            .font(Typography.button)
                            .foregroundColor(.dnaTextSecondary)
                        
                        Text("Tomar foto del documento")
                            .font(Typography.caption)
                            .foregroundColor(.dnaTextSecondary.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16))
                        .foregroundColor(.dnaTextSecondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.dnaSurface)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Camera Preview View
    private func cameraPreviewView(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Imagen Capturada")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.dnaOrange, lineWidth: 2)
                )
            
            Button("Procesar Imagen") {
                processImage(image)
            }
            .font(Typography.button)
            .foregroundColor(.dnaBackground)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.dnaOrange)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Scanned Text View
    private var scannedTextView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Texto Escaneado")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            ScrollView {
                Text(scannedText)
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxHeight: 200)
            .padding()
            .background(Color.dnaSurfaceLight)
            .cornerRadius(8)
            
            HStack {
                Button("Copiar Texto") {
                    UIPasteboard.general.string = scannedText
                }
                .font(Typography.buttonSmall)
                .foregroundColor(.dnaOrange)
                
                Spacer()
                
                Button("Procesar con IA") {
                    processText(scannedText)
                }
                .font(Typography.buttonSmall)
                .foregroundColor(.dnaBackground)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.dnaOrange)
                .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Processing Results View
    private func processingResultsView(_ result: OCRResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resultados del Procesamiento")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(result.data.processedData.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text(key.capitalized)
                            .font(Typography.body)
                            .foregroundColor(.dnaTextSecondary.opacity(0.8))
                            .frame(width: 100, alignment: .leading)
                        
                        Text(value)
                            .font(Typography.body)
                            .foregroundColor(.dnaTextSecondary)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.dnaSurfaceLight)
            .cornerRadius(8)
            
            HStack {
                Text("Confianza")
                    .font(Typography.bodySmall)
                    .foregroundColor(.dnaTextSecondary.opacity(0.7))
                
                Spacer()
                
                Text(String(format: "%.1f%%", result.data.confidence * 100))
                    .font(Typography.body)
                    .foregroundColor(result.data.confidence > 0.8 ? .green : .yellow)
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Recent Documents View
    private var recentDocumentsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Documentos Recientes")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            // TODO: Load and display recent scanned documents
            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    DocumentRowView(
                        documentType: documentTypes[index],
                        timestamp: Date().addingTimeInterval(-TimeInterval(index * 3600)),
                        status: "Procesado"
                    )
                }
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Process Image
    private func processImage(_ image: UIImage) {
        guard let user = authManager.currentUser else { return }
        
        isProcessing = true
        
        Task {
            do {
                // Convert image to base64
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    let base64String = imageData.base64EncodedString()
                    
                    // Use VisionKit for OCR on iOS
                    let ocrText = try await performOCROnDevice(image: image)
                    
                    await MainActor.run {
                        self.scannedText = ocrText
                        self.isProcessing = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    // Handle error
                }
            }
        }
    }
    
    // MARK: - Process Text
    private func processText(_ text: String) {
        guard let user = authManager.currentUser else { return }
        
        isProcessing = true
        
        Task {
            do {
                let result = try await SupabaseService.shared.processDocumentOCR(
                    ocrText: text,
                    documentType: selectedDocumentType,
                    documentId: nil,
                    userId: user.id
                )
                
                await MainActor.run {
                    self.processingResult = result
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    // Handle error
                }
            }
        }
    }
    
    // MARK: - Perform OCR on Device
    private func performOCROnDevice(image: UIImage) async throws -> String {
        // This would use VisionKit's DataScannerViewController in a real implementation
        // For now, return placeholder text
        return """
        Documento escaneado exitosamente.
        Tipo: \(selectedDocumentType.displayName)
        Fecha: \(Date().description)
        [Este es un resultado de prueba - en producción se usaría VisionKit]
        """
    }
}

// MARK: - Document Type Button Component
struct DocumentTypeButton: View {
    let type: DocumentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: getDocumentIcon())
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .dnaBackground : .dnaTextSecondary)
                
                Text(type.displayName)
                    .font(Typography.buttonSmall)
                    .foregroundColor(isSelected ? .dnaBackground : .dnaTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 100, height: 80)
            .padding()
            .background(isSelected ? Color.dnaOrange : Color.dnaSurfaceLight)
            .cornerRadius(8)
        }
    }
    
    private func getDocumentIcon() -> String {
        switch type {
        case .bol: return "doc.text"
        case .contract: return "doc.plaintext"
        case .permit: return "shield.checkered"
        case .insurance: return "shield"
        case .eld: return "clock.arrow.circlepath"
        case .receipt: return "receipt"
        case .invoice: return "doc.text.badge.plus"
        case .maintenance: return "wrench"
        }
    }
}

// MARK: - Document Row View Component
struct DocumentRowView: View {
    let documentType: DocumentType
    let timestamp: Date
    let status: String
    
    var body: some View {
        HStack {
            Image(systemName: getDocumentIcon())
                .font(.system(size: 20))
                .foregroundColor(.dnaOrange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(documentType.displayName)
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary)
                
                Text(timestamp.relativeTime)
                    .font(Typography.caption)
                    .foregroundColor(.dnaTextSecondary.opacity(0.7))
            }
            
            Spacer()
            
            Text(status)
                .font(Typography.caption)
                .foregroundColor(status == "Procesado" ? .green : .yellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((status == "Procesado" ? Color.green : Color.yellow).opacity(0.2))
                .cornerRadius(12)
        }
        .padding()
        .background(Color.dnaSurfaceLight)
        .cornerRadius(8)
    }
    
    private func getDocumentIcon() -> String {
        switch documentType {
        case .bol: return "doc.text"
        case .contract: return "doc.plaintext"
        case .permit: return "shield.checkered"
        case .insurance: return "shield"
        case .eld: return "clock.arrow.circlepath"
        case .receipt: return "receipt"
        case .invoice: return "doc.text.badge.plus"
        case .maintenance: return "wrench"
        }
    }
}

// MARK: - Date Extension for Relative Time
extension Date {
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    DocumentScanView()
        .environmentObject(AuthManager())
        .environmentObject(AppState())
}

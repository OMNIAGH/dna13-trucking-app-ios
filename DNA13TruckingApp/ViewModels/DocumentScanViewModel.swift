import Foundation
import Combine
import SwiftUI
import UIKit

class DocumentScanViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isScanning: Bool = false
    @Published var isProcessing: Bool = false
    @Published var extractedText: String = ""
    @Published var recognizedFields: [ExtractedField] = []
    @Published var documentType: DocumentType = .unknown
    @Published var isValidDocument: Bool = false
    @Published var errorMessage: String?
    @Published var showConfirmation: Bool = false
    
    // Documentos guardados
    @Published var savedDocuments: [ScannedDocument] = []
    @Published var recentDocuments: [ScannedDocument] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let supabaseService: SupabaseService = SupabaseService.shared
    
    init() {
        loadRecentDocuments()
    }
    
    func captureImage(_ image: UIImage) {
        capturedImage = image
        documentType = .unknown
        extractedText = ""
        recognizedFields = []
        isValidDocument = false
        errorMessage = nil
    }
    
    func processImage() {
        guard let image = capturedImage else {
            errorMessage = "No hay imagen para procesar"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        // Simular procesamiento de OCR
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            sleep(2) // Simular tiempo de procesamiento
            
            DispatchQueue.main.async {
                self?.performOCRProcessing(image: image)
            }
        }
    }
    
    private func performOCRProcessing(image: UIImage) {
        // Simular extracción de texto basada en el tipo de documento
        if documentType == .bol || documentType == .invoice {
            extractedText = generateSampleText(for: documentType)
            parseExtractedFields()
        } else {
            extractedText = """
            Documento detectado - OCR en proceso
            Fecha: 06/11/2025
            Número: 12345
            Cliente: Logistics Corp
            Total: $1,500.00
            """
            parseExtractedFields()
        }
        
        isProcessing = false
    }
    
    private func generateSampleText(for type: DocumentType) -> String {
        switch type {
        case .bol:
            return """
            BILL OF LADING
            Bill #: BL-2025-001
            Date: 06/11/2025
            Shipper: ABC Manufacturing
            123 Industrial Blvd
            Phoenix, AZ 85001
            
            Consignee: XYZ Distribution
            456 Warehouse Dr
            Dallas, TX 75201
            
            Commodity: Electronics
            Weight: 2,500 lbs
            Pieces: 15
            Value: $15,000.00
            
            Driver: John Doe
            Truck: TRK-001
            """
        case .invoice:
            return """
            INVOICE
            Invoice #: INV-2025-456
            Date: 06/11/2025
            Due Date: 20/11/2025
            
            Bill To: Logistics Corp
            789 Commerce St
            Houston, TX 77001
            
            Description: Freight Services
            Amount: $1,500.00
            Tax: $120.00
            Total: $1,620.00
            
            Payment Terms: Net 30
            """
        case .cmr:
            return """
            CMR CONVENTION
            CMR #: CMR-2025-789
            Date: 06/11/2025
            
            Sender: European Logistics
            Receiver: US Transport
            
            Goods: Machinery
            Weight: 3,200 kg
            """
        case .pod:
            return """
            PROOF OF DELIVERY
            POD #: POD-2025-321
            Delivery Date: 06/11/2025
            Time: 14:30
            
            Delivered to: Warehouse Manager
            Signature: [Digital]
            
            Condition: Good
            Notes: All items delivered intact
            """
        case .maintenance:
            return """
            MAINTENANCE REPORT
            Report #: MNT-2025-654
            Date: 06/11/2025
            Vehicle: TRK-001
            
            Service Type: Regular Maintenance
            Mileage: 125,450
            
            Services Performed:
            - Oil change
            - Tire rotation
            - Brake inspection
            
            Next Service: 130,000 miles
            """
        case .unknown:
            return ""
        }
    }
    
    private func parseExtractedFields() {
        recognizedFields = []
        
        // Detectar tipo de documento
        if extractedText.contains("BILL OF LADING") || extractedText.contains("Bill #:") {
            documentType = .bol
        } else if extractedText.contains("INVOICE") || extractedText.contains("Invoice #:") {
            documentType = .invoice
        } else if extractedText.contains("CMR") {
            documentType = .cmr
        } else if extractedText.contains("PROOF OF DELIVERY") {
            documentType = .pod
        } else if extractedText.contains("MAINTENANCE REPORT") {
            documentType = .maintenance
        }
        
        // Extraer campos específicos
        parseCommonFields()
        parseDocumentSpecificFields()
        
        // Validar documento
        validateDocument()
    }
    
    private func parseCommonFields() {
        // Extraer número de documento
        if let numberRange = extractedText.range(of: #"(?i)(bill|invoice|cmr|pod|report)#:\s*(\w+-\d+|\d+)"#, options: .regularExpression) {
            let number = String(extractedText[numberRange])
                .replacingOccurrences(of: #"(?i)(bill|invoice|cmr|pod|report)#:\s*"#, with: "", options: .regularExpression)
            recognizedFields.append(ExtractedField(key: "Número", value: number, confidence: 0.9))
        }
        
        // Extraer fecha
        if let dateRange = extractedText.range(of: #"\b(\d{1,2}[/-]\d{1,2}[/-]\d{4})\b"#, options: .regularExpression) {
            let date = String(extractedText[dateRange])
            recognizedFields.append(ExtractedField(key: "Fecha", value: date, confidence: 0.85))
        }
        
        // Extraer nombres
        if let nameRange = extractedText.range(of: #"(?i)(shipper|consignee|bill to|receiver):\s*([A-Za-z\s&.,]+)"#, options: .regularExpression) {
            let name = String(extractedText[nameRange])
                .replacingOccurrences(of: #"(?i)(shipper|consignee|bill to|receiver):\s*"#, with: "", options: .regularExpression)
            recognizedFields.append(ExtractedField(key: "Entidad", value: name.trimmingCharacters(in: .whitespacesAndNewlines), confidence: 0.8))
        }
        
        // Extraer valores monetarios
        if let valueRange = extractedText.range(of: #"\$\s?([\d,]+\.?\d*)"#, options: .regularExpression) {
            let value = String(extractedText[valueRange])
            recognizedFields.append(ExtractedField(key: "Valor", value: value, confidence: 0.95))
        }
    }
    
    private func parseDocumentSpecificFields() {
        switch documentType {
        case .bol:
            // Campos específicos para Bill of Lading
            if extractedText.contains("Commodity:") {
                if let commodityRange = extractedText.range(of: #"(?i)commodity:\s*([A-Za-z\s]+)"#, options: .regularExpression) {
                    let commodity = String(extractedText[commodityRange])
                        .replacingOccurrences(of: #"(?i)commodity:\s*"#, with: "", options: .regularExpression)
                    recognizedFields.append(ExtractedField(key: "Mercancía", value: commodity.trimmingCharacters(in: .whitespacesAndNewlines), confidence: 0.8))
                }
            }
            
            if let weightRange = extractedText.range(of: #"(?i)weight:\s*([\d,]+)\s*(lbs|kg)"#, options: .regularExpression) {
                let weight = String(extractedText[weightRange])
                    .replacingOccurrences(of: #"(?i)weight:\s*"#, with: "", options: .regularExpression)
                recognizedFields.append(ExtractedField(key: "Peso", value: weight, confidence: 0.9))
            }
            
        case .invoice:
            // Campos específicos para factura
            if extractedText.contains("Due Date:") {
                if let dueDateRange = extractedText.range(of: #"(?i)due date:\s*(\d{1,2}[/-]\d{1,2}[/-]\d{4})"#, options: .regularExpression) {
                    let dueDate = String(extractedText[dueDateRange])
                        .replacingOccurrences(of: #"(?i)due date:\s*"#, with: "", options: .regularExpression)
                    recognizedFields.append(ExtractedField(key: "Fecha Vencimiento", value: dueDate, confidence: 0.85))
                }
            }
            
        default:
            break
        }
    }
    
    private func validateDocument() {
        // Validar que el documento tenga al menos un campo reconocido
        isValidDocument = !recognizedFields.isEmpty && !extractedText.isEmpty
    }
    
    func saveDocument() {
        guard let image = capturedImage, isValidDocument else { return }
        
        let document = ScannedDocument(
            id: UUID().uuidString,
            image: image,
            extractedText: extractedText,
            fields: recognizedFields,
            documentType: documentType,
            timestamp: Date(),
            isProcessed: true
        )
        
        savedDocuments.append(document)
        recentDocuments.insert(document, at: 0)
        
        // Guardar en base de datos (simulado)
        saveToDatabase(document)
        showConfirmation = true
    }
    
    private func saveToDatabase(_ document: ScannedDocument) {
        // Aquí se guardaría el documento en Supabase
        print("Documento guardado: \(document.id)")
    }
    
    private func loadRecentDocuments() {
        // Cargar documentos recientes desde la base de datos
        recentDocuments = [
            ScannedDocument(
                id: "1",
                image: UIImage(systemName: "doc.text")!,
                extractedText: "Bill of Lading - Documento de transporte",
                fields: [],
                documentType: .bol,
                timestamp: Date().addingTimeInterval(-86400),
                isProcessed: true
            )
        ]
    }
    
    func retakePhoto() {
        capturedImage = nil
        extractedText = ""
        recognizedFields = []
        documentType = .unknown
        isValidDocument = false
        errorMessage = nil
    }
    
    func manualEntry() {
        // Permitir entrada manual de datos
        showManualEntryView = true
    }
    
    @Published var showManualEntryView: Bool = false
}

// MARK: - Models
struct ExtractedField {
    let key: String
    let value: String
    let confidence: Double
}

struct ScannedDocument: Identifiable {
    let id: String
    let image: UIImage
    let extractedText: String
    let fields: [ExtractedField]
    let documentType: DocumentType
    let timestamp: Date
    let isProcessed: Bool
}

enum DocumentType: String, CaseIterable {
    case bol = "Bill of Lading"
    case invoice = "Factura"
    case cmr = "CMR"
    case pod = "Proof of Delivery"
    case maintenance = "Mantenimiento"
    case unknown = "Desconocido"
    
    var displayName: String {
        return rawValue
    }
}
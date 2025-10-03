import SwiftUI

struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let isEnabled: Bool
    
    init(
        label: String,
        text: Binding<String>,
        placeholder: String = "",
        keyboardType: UIKeyboardType = .default,
        isEnabled: Bool = true
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder.isEmpty ? label : placeholder
        self.keyboardType = keyboardType
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: NomisTheme.smallSpacing) {
            Text(label)
                .font(.subheadline.weight(NomisTheme.headlineWeight))
                .foregroundColor(NomisTheme.text)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .disabled(!isEnabled)
                .textFieldStyle()
                .opacity(isEnabled ? 1.0 : 0.6)
        }
    }
}

struct LabeledNumberField: View {
    let label: String
    @Binding var value: Double?
    let placeholder: String
    let isEnabled: Bool
    let unit: String
    
    @State private var textValue: String = ""
    
    init(
        label: String,
        value: Binding<Double?>,
        placeholder: String = "",
        isEnabled: Bool = true,
        unit: String = ""
    ) {
        self.label = label
        self._value = value
        self.placeholder = placeholder.isEmpty ? label : placeholder
        self.isEnabled = isEnabled
        self.unit = unit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: NomisTheme.smallSpacing) {
            Text(label)
                .font(.subheadline.weight(NomisTheme.headlineWeight))
                .foregroundColor(NomisTheme.text)
            
            HStack {
                TextField(placeholder, text: $textValue)
                    .keyboardType(.decimalPad)
                    .disabled(!isEnabled)
                    .onChange(of: textValue) { _, newValue in
                        value = NomisFormatters.parseDouble(from: newValue)
                    }
                .onAppear {
                    updateTextValue()
                }
                .onChange(of: value) { _, _ in
                    updateTextValue()
                }
                
                if !unit.isEmpty {
                    Text(unit)
                        .foregroundColor(NomisTheme.secondaryText)
                        .font(.body)
                }
            }
            .textFieldStyle()
            .opacity(isEnabled ? 1.0 : 0.6)
        }
    }
    
    private func updateTextValue() {
        if let val = value {
            textValue = NomisFormatters.safeFormat(val)
        } else {
            textValue = ""
        }
    }
}

struct LabeledIntegerField: View {
    let label: String
    @Binding var value: Int?
    let placeholder: String
    let isEnabled: Bool
    
    @State private var textValue: String = ""
    
    init(
        label: String,
        value: Binding<Int?>,
        placeholder: String = "",
        isEnabled: Bool = true
    ) {
        self.label = label
        self._value = value
        self.placeholder = placeholder.isEmpty ? label : placeholder
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: NomisTheme.smallSpacing) {
            Text(label)
                .font(.subheadline.weight(NomisTheme.headlineWeight))
                .foregroundColor(NomisTheme.text)
            
            TextField(placeholder, text: $textValue)
                .keyboardType(.numberPad)
                .disabled(!isEnabled)
                .textFieldStyle()
                .opacity(isEnabled ? 1.0 : 0.6)
                .onChange(of: textValue) { _, newValue in
                    value = NomisFormatters.parseInt(from: newValue)
                }
                .onAppear {
                    updateIntegerTextValue()
                }
                .onChange(of: value) { _, _ in
                    updateIntegerTextValue()
                }
        }
    }
    
    private func updateIntegerTextValue() {
        if let val = value {
            textValue = NomisFormatters.formatInteger(val)
        } else {
            textValue = ""
        }
    }
}

struct LabeledDateField: View {
    let label: String
    @Binding var date: Date
    let displayedComponents: DatePickerComponents
    let isEnabled: Bool
    
    init(
        label: String,
        date: Binding<Date>,
        displayedComponents: DatePickerComponents = [.date, .hourAndMinute],
        isEnabled: Bool = true
    ) {
        self.label = label
        self._date = date
        self.displayedComponents = displayedComponents
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: NomisTheme.smallSpacing) {
            Text(label)
                .font(.subheadline.weight(NomisTheme.headlineWeight))
                .foregroundColor(NomisTheme.text)
            
            DatePicker("", selection: $date, displayedComponents: displayedComponents)
                .labelsHidden()
                .disabled(!isEnabled)
                .opacity(isEnabled ? 1.0 : 0.6)
                .environment(\.locale, NomisFormatters.turkishLocale)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LabeledTextField(
            label: "Model",
            text: .constant("Test Model"),
            placeholder: "Model adı girin"
        )
        
        LabeledNumberField(
            label: "Ağırlık",
            value: .constant(15.75),
            unit: "gr"
        )
        
        LabeledIntegerField(
            label: "Ayar",
            value: .constant(18)
        )
        
        LabeledDateField(
            label: "Tarih",
            date: .constant(Date())
        )
    }
    .padding()
}

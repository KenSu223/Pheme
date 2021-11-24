//
//  SettingsView.swift
//  StorageV1
//
//  Created by Chen Gong on 11/23/21.
//

import SwiftUI
import CodeScanner

struct SettingsView : View {
    
    @EnvironmentObject private var identity: Identity
    @EnvironmentObject private var contacts: Contacts
    var username : String
    
    
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    @State private var isShowingScanner = false
    var body : some View{
        let key = identity.myKey()
        let id = identity.myID()
        let name = identity.myName()
        
        return VStack {
        
            Image(uiImage: generateQRCode2(from: "\(name)\n\(key)\n\(id)"))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding()
            
            Spacer()
            
            Button(action: {
                self.isShowingScanner = true
            }) {
                Image(systemName: "qrcode.viewfinder")
                                    .resizable()
                                    .frame(width: 75, height: 75)
                                    .padding()
                                    .foregroundColor(Color("Color"))
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes:[.qr], completion:self.handleScan)
            
            }
        }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
        .background(Color.white)
        .clipShape(shape())
        .animation(.default)
        .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom)
        .padding(.bottom)
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        self.isShowingScanner = false
        
        switch result {
            case .success(let code):
                let details = code.components(separatedBy: "\n")
                guard details.count == 3 else { return }

			contacts.searchOrCreate(nn: details[0], id: details[2], keyString: details[1])
                
        case .failure(_):
                print("Scanning failed")
        }
    }
    
    func generateQRCode2(from string: String) -> UIImage {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage{
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent){
                return UIImage(cgImage: cgimg)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }

}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(username: "Pheme")
    }
}
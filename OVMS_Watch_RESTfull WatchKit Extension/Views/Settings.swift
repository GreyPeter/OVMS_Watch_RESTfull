//
//  Settings.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import SwiftUI

struct Settings: View {
    @Binding var userName: String
    @Binding  var password: String
        var body: some View {
            VStack {
                TextField("OVMS Username", text: $userName)
                SecureField("Password", text: $password)
            }
        }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings(userName: .constant(""), password: .constant(""))
    }
}

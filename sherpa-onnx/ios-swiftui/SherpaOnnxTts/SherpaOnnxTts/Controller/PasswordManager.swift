//
//  PasswordManager.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 11/5/24.
//

import Foundation

class PasswordManager: ObservableObject {
    @Published var hasPassword: Bool = false
    @Published var recoveryCode: String?
    @Published var justCreatedPassword: Bool = false
    
    private let passwordKey = "appPassword"
    private let recoveryCodeKey = "recoveryCode"
    private var temporaryPassword: String?
    
    init() {
        // kevin: check if a password already exists on init (temporarily using nsuserdefaults)
        hasPassword = UserDefaults.standard.string(forKey: passwordKey) != nil
        recoveryCode = UserDefaults.standard.string(forKey: recoveryCodeKey)
    }
    
    // kevin: function to set password (temporarily using nsuserdefaults)
    func setPassword(_ password: String) -> String? {
        UserDefaults.standard.set(password, forKey: passwordKey)
        hasPassword = true
        
        // Generate and store a new recovery code
        let recoveryCode = generateRecoveryCode()
        UserDefaults.standard.set(recoveryCode, forKey: recoveryCodeKey)
        
        return recoveryCode
    }
    
    // kevin: function to remove password (temporarily using nsuserdefaults)
    func removePassword() {
        UserDefaults.standard.removeObject(forKey: passwordKey)
        UserDefaults.standard.removeObject(forKey: recoveryCodeKey)
        recoveryCode = nil
        hasPassword = false
    }
    
    // kevin: function to validate password
    func validatePassword(_ inputPassword: String) -> Bool {
        if let savedPassword = UserDefaults.standard.string(forKey: passwordKey) {
            return inputPassword == savedPassword
        }
        return false
    }
    
    func recoverAccount(with code: String, newPassword: String? = nil) -> Bool {
        guard let storedCode = UserDefaults.standard.string(forKey: recoveryCodeKey),
              storedCode == code else {
            return false
        }
        
        if let newPassword = newPassword {
            UserDefaults.standard.set(newPassword, forKey: passwordKey)
            hasPassword = true
        } else {
            removePassword()
        }
        
        UserDefaults.standard.removeObject(forKey: recoveryCodeKey)
        recoveryCode = nil
        
        return true
    }
    
    private func generateRecoveryCode() -> String {
        let code = String(format: "%06d", Int.random(in: 0..<1000000))
        return code
    }
    
    func generateTemporaryRecoveryCode(for newPassword: String) -> String? {
        justCreatedPassword = false
        temporaryPassword = newPassword
        let code = generateRecoveryCode()
        recoveryCode = code
        return code
    }
    
    func finalizeNewPassword(_ newPassword: String) {
        guard newPassword == temporaryPassword else { return }
        UserDefaults.standard.set(newPassword, forKey: passwordKey)
        hasPassword = true
        justCreatedPassword = true
        
        if let code = recoveryCode {
            UserDefaults.standard.set(code, forKey: recoveryCodeKey)
        }
        temporaryPassword = nil
    }
}


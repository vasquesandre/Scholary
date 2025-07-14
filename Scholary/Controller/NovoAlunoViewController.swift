//
//  NovoAlunoViewController.swift
//  Scholary
//
//  Created by Andre Vasques on 10/07/25.
//

import UIKit
import FirebaseFirestore

class NovoAlunoViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    @IBOutlet weak var nomeAlunoTextField: UITextField!
    
    
    @IBAction func closeButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
    
    @IBAction func adicionarButton(_ sender: UIButton) {
        guard let text = nomeAlunoTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return
        }
        
        novoAluno(nome: text)
    }
    
    
    func novoAluno(nome: String) {
        db.collection("alunos").addDocument(data: [
            "nome": nome
        ]) { (error) in
            if let e = error {
                self.validationAlert(title: "Erro", message: "Não foi possível adicionar o aluno, tente novamente.")
                print("Issue saving to firestore, \(e)")
            } else {
                self.validationAlert(title: "Sucesso", message: "Aluno adicionado com sucesso.")
                self.nomeAlunoTextField.text = ""
            }
        }
    }
    
}

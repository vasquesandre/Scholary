//
//  EditarAlunoViewController.swift
//  Scholary
//
//  Created by Andre Vasques on 10/07/25.
//

import UIKit
import FirebaseFirestore

class EditarAlunoViewController: UIViewController {
    
    let db = Firestore.firestore()
    
    var aluno: Aluno?
    
    @IBOutlet weak var nomeAlunoTextField: UITextField!
    
    @IBAction func closeButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let aluno = aluno {
            nomeAlunoTextField.text = aluno.nome
        }
    }
    
    @IBAction func salvarButton(_ sender: UIButton) {
        let novoNome = nomeAlunoTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !novoNome.isEmpty {
            guard let aluno = aluno else { return }
            self.db.collection("alunos").document(aluno.id).updateData(["nome": novoNome]) { err in
                if let err = err {
                    print("Erro ao renomear aluno: \(err.localizedDescription)")
                } else {
                    self.validationWithDismiss(title: "\(novoNome)", message: "Nome do aluno atualizado") {
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
}

//
//  AdicionarAlunosTableViewController.swift
//  Scholary
//
//  Created by Andre Vasques on 07/07/25.
//

import UIKit
import FirebaseFirestore

class AdicionarAlunosTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    
    var alunos: [Aluno] = []
    var alunosSelecionados: Set<Int> = []
    
    var salaSelecionada: Sala?
    
    @IBOutlet weak var novoAlunoButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        carregarTodosOsAlunos()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alunos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let aluno = alunos[indexPath.row]
        
        if let salaNome = aluno.salaNome, !salaNome.isEmpty {
            cell.textLabel?.text = "\(aluno.nome) | \(salaNome)"
        } else {
            cell.textLabel?.text = aluno.nome
        }
        
        if alunosSelecionados.contains(indexPath.row) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
        
    }
    
    //MARK: - Novo Aluno Button Pressed
    
    @IBAction func novoAlunoButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Novo Aluno", message: "Adicione um novo aluno para ser vinculado à uma sala posteriormente.", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Adicionar", style: .default) { action in
            guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                return
            }
            
            let novoAluno = text
            self.novoAluno(nome: novoAluno)
        }
        
        let cancel = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Nome do aluno"
            textField = alertTextField
        }
        
        alert.addAction(action)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
        
    }

    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        guard let salaSelecionada = salaSelecionada else {
            let alert = UIAlertController(title: "Erro", message: "Nenhuma sala selecionada.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        let alunosParaVincular = alunosSelecionados.map { alunos[$0] }
        for aluno in alunosParaVincular {
            db.collection("alunos").document(aluno.id).updateData(["sala": salaSelecionada.id]) { error in
                if let error = error {
                    print("Erro ao vincular sala para aluno \(aluno.nome): \(error)")
                } else {
                    let alert = UIAlertController(title: "Alunos Vinculados", message: "Os alunos selecionados foram adicionados à sala \(salaSelecionada.nome)", preferredStyle: .alert)
                    
                    let message = UIAlertAction(title: "OK", style: .default, handler: nil)
                    
                    alert.addAction(message)
                    
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    //MARK: - Data Manipulation
    
    func novoAluno(nome: String) {
        db.collection("alunos").addDocument(data: [
            "nome": nome
        ]) { (error) in
            if let e = error {
                print("Issue saving to firestore, \(e)")
            } else {
                print("Successfully saved")
            }
        }
    }
    
    func carregarTodosOsAlunos() {
        
        db.collection("alunos")
            .order(by: "nome")
            .addSnapshotListener { (snapshot, error) in
            if let e = error {
                print("Error retrieving data form Firestore -> \(e)")
            } else {
                if let snapshotDocuments = snapshot?.documents {
                    self.alunos.removeAll()
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        print(data)
                        let alunoID = doc.documentID
                        let nome = data["nome"] as? String ?? ""
                        let salaId = data["sala"] as? String
                        if let salaId = salaId, !salaId.isEmpty {
                            self.db.collection("salas").document(salaId).getDocument { (salaSnapshot, error) in
                                let salaNome = salaSnapshot?.data()?["nome"] as? String
                                let aluno = Aluno(id: alunoID, nome: nome, salaId: salaId, salaNome: salaNome)
                                self.alunos.append(aluno)
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                    
                                }
                            }
                        } else {
                            let aluno = Aluno(id: alunoID, nome: nome, salaId: nil, salaNome: nil)
                            self.alunos.append(aluno)
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                    print(snapshotDocuments)
                    print(self.alunos)
                }
            }
        }
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if alunosSelecionados.contains(indexPath.row) {
            alunosSelecionados.remove(indexPath.row)
        } else {
            alunosSelecionados.insert(indexPath.row)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
        tableView.deselectRow(at: indexPath, animated: true)
        atualizarBotoes()
    }
    
    func atualizarBotoes() {
        if alunosSelecionados.isEmpty {
            doneButton.isEnabled = false
        } else {
            doneButton.isEnabled = true
        }
    }

}


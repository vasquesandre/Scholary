//
//  SalasViewControllerTableViewController.swift
//  Scholary
//
//  Created by Andre Vasques on 07/07/25.
//

import UIKit
import FirebaseFirestore

class SalasTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    
    var salas: [Sala] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        carregarSalas()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return salas.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SalasCell", for: indexPath)
        
        let sala = salas[indexPath.row]
        
        cell.textLabel?.text = sala.nome
        
        return cell
        
    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Adicionar Sala", message: "Adicione uma nova sala (ex. 4ºA), para atribuir um professor e alunos.", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Adicionar", style: .default) { action in
            guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                return
            }
            
            let novaSala = text
            self.criarSala(sala: novaSala)
        }
        
        let cancel = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Nome da sala"
            textField = alertTextField
        }
        
        alert.addAction(action)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    //MARK: - Delete Data from Swipe
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let sala = self.salas[indexPath.row]
        let alunosRef = self.db.collection("alunos").whereField("sala", isEqualTo: sala.id)
        
        let desvincularAction = UIContextualAction(style: .normal, title: "Desvincular") { _, _, completionHandler in
            alunosRef.getDocuments { (snapshot, error) in
                if let error = error {
                    print("Erro ao buscar alunos: \(error.localizedDescription)")
                } else {
                    let documentos = snapshot?.documents ?? []
                    var desvinculados = 0
                    let dispatchGroup = DispatchGroup()
                    for doc in documentos {
                        dispatchGroup.enter()
                        let alunoRef = self.db.collection("alunos").document(doc.documentID)
                        alunoRef.updateData(["sala": ""]) { err in
                            if err == nil {
                                desvinculados += 1
                            }
                            dispatchGroup.leave()
                        }
                    }
                    dispatchGroup.notify(queue: .main) {
                        self.validationAlert(title: "\(desvinculados) Alunos Desvinculados", message: "")
                    }
                }
                completionHandler(true)
                
            }
        }
        desvincularAction.backgroundColor = .orange
        
        let renomearAction = UIContextualAction(style: .normal, title: "Renomear") { _, _, completionHandler in
            let alert = UIAlertController(title: "Renomear Sala", message: "Informe o novo nome da sala.", preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = sala.nome
            }
            alert.addAction(UIAlertAction(title: "Salvar", style: .default, handler: { _ in
                let novoNome = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !novoNome.isEmpty {
                    self.db.collection("salas").document(sala.id).updateData(["nome": novoNome]) { err in
                        if let err = err {
                            print("Erro ao renomear sala: \(err.localizedDescription)")
                        } else {
                            self.salas[indexPath.row].nome = novoNome
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                            self.validationAlert(title: "\(novoNome)", message: "Nome da sala atualizado")
                        }
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            completionHandler(true)
        }

        let deleteAction = UIContextualAction(style: .destructive, title: "Apagar") { _, _, completionHandler in
            self.salas.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            alunosRef.getDocuments { (snapshot, error) in
                if let error = error {
                    print("Erro ao buscar alunos: \(error.localizedDescription)")
                    return
                }
                let documentos = snapshot?.documents ?? []
                var desvinculados = 0
                let dispatchGroup = DispatchGroup()
                for doc in documentos {
                    dispatchGroup.enter()
                    let alunoRef = self.db.collection("alunos").document(doc.documentID)
                    alunoRef.updateData(["sala": ""]) { err in
                        if err == nil {
                            desvinculados += 1
                        }
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    self.db.collection("salas").document(sala.id).delete { err in
                        if let err = err {
                            print("Erro ao remover sala: \(err.localizedDescription)")
                        } else {
                            self.validationAlert(title: "Sala Removida", message: "\(desvinculados) alunos desvinculados da sala.")
                        }
                    }
                }
            }
            completionHandler(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction, desvincularAction, renomearAction])
    }
    
    //MARK: - Data Manipulation
    
    func criarSala(sala text: String) {
        
        db.collection("salas").addDocument(data: [
            "nome": text
        ]) { (error) in
            if let e = error {
                print("Issue saving to firestore, \(e)")
            } else {
                print("Successfully saved")
            }
        }
        
    }
    
    func carregarSalas() {
        
        db.collection("salas")
            .order(by: "nome")
            .addSnapshotListener { (snapshot, error) in
            if let e = error {
                print("Error retrieving data form Firestore -> \(e)")
            } else {
                if let snapshotDocuments = snapshot?.documents {
                    self.salas.removeAll()
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        if let nome = data["nome"] as? String {
                            let sala = Sala(id: doc.documentID, nome: nome)
                            self.salas.append(sala)
                        }
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToAlunos", sender: self)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! AlunosTableViewController
        
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.salaSelecionada = salas[indexPath.row]
        }
    }
    
    //MARK: - Validation Alert
    
    func validationAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let message = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(message)
        self.present(alert, animated: true, completion: nil)
    }
    
}

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

        let deleteAction = UIContextualAction(style: .destructive, title: "Apagar") { _, _, completionHandler in
            let salaASerRemovida = self.salas[indexPath.row]
            let salaId = salaASerRemovida.id
            self.salas.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            let alunosRef = self.db.collection("alunos").whereField("sala", isEqualTo: salaId)
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
                    self.db.collection("salas").document(salaId).delete { err in
                        if let err = err {
                            print("Erro ao remover sala: \(err.localizedDescription)")
                        } else {
                            // Mostrar alerta
                            let alerta = UIAlertController(title: "Sala removida", message: "Desvinculados \(desvinculados) alunos da sala.", preferredStyle: .alert)
                            alerta.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(alerta, animated: true, completion: nil)
                        }
                    }
                }
            }
            completionHandler(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
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
    

}

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
        
        performSegue(withIdentifier: "goToNovoAluno", sender: self)
        
    }
    
    //MARK: - Done Button Pressed

    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        guard let salaSelecionada = salaSelecionada else {
            let alert = UIAlertController(title: "Erro", message: "Nenhuma sala selecionada.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        let alunosParaVincular = alunosSelecionados.map { alunos[$0] }
        let dispatchGroup = DispatchGroup()
        for aluno in alunosParaVincular {
            dispatchGroup.enter()
            db.collection("alunos").document(aluno.id).updateData(["sala": salaSelecionada.id]) { error in
                if let error = error {
                    print("Erro ao vincular sala para aluno \(aluno.nome): \(error)")
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            if let navigationController = self.navigationController {
                navigationController.popViewController(animated: true)
                self.validationAlert(title: "Alunos vinculados", message: "\(self.alunosSelecionados.count) foram vinculados à \(salaSelecionada.nome)")
            }
        }
    }

    //MARK: - Data Manipulation
    
    func carregarTodosOsAlunos() {
        
        db.collection("alunos")
            .order(by: "nome")
            .addSnapshotListener { (snapshot, error) in
            if let e = error {
                print("Error retrieving data form Firestore -> \(e)")
            } else {
                if let snapshotDocuments = snapshot?.documents {
                    self.alunos.removeAll()
                    let dispatchGroup = DispatchGroup()
                    for doc in snapshotDocuments {
                        dispatchGroup.enter()
                        let data = doc.data()
                        let alunoID = doc.documentID
                        let nome = data["nome"] as? String ?? ""
                        let salaId = data["sala"] as? String
                        if let salaId = salaId, !salaId.isEmpty {
                            self.db.collection("salas").document(salaId).getDocument { (salaSnapshot, error) in
                                let salaNome = salaSnapshot?.data()?["nome"] as? String
                                let aluno = Aluno(id: alunoID, nome: nome, salaId: salaId, salaNome: salaNome)
                                self.alunos.append(aluno)
                                dispatchGroup.leave()
                            }
                        } else {
                            let aluno = Aluno(id: alunoID, nome: nome, salaId: nil, salaNome: nil)
                            self.alunos.append(aluno)
                            dispatchGroup.leave()
                        }
                    }
                    dispatchGroup.notify(queue: .main) {
                        self.tableView.reloadData()
                    }
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

//MARK: - UISearchBarDelegate

extension AdicionarAlunosTableViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            carregarTodosOsAlunos()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        } else{
            alunos = alunos.filter { $0.nome.localizedCaseInsensitiveContains(searchText) }
            
            tableView.reloadData()
        }
    }
}

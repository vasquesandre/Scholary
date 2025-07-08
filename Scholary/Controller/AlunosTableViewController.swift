//
//  AlunosTableViewController.swift
//  Scholary
//
//  Created by Andre Vasques on 07/07/25.
//

import UIKit
import FirebaseFirestore

class AlunosTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    
    var alunos: [Aluno] = []
    
    var salaSelecionada: Sala? {
        didSet {
            carregarAlunos()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        if let sala = salaSelecionada {
            title = sala.nome
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alunos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let aluno = alunos[indexPath.row]
        
        cell.textLabel?.text = aluno.nome
        
        return cell
        
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.reloadData()
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let deleteAction = UIContextualAction(style: .destructive, title: "Apagar") { _, _, completionHandler in
            let alunoASerDesvinculado = self.alunos[indexPath.row]
            self.alunos.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            let alunoRef = self.db.collection("alunos").document(alunoASerDesvinculado.id)
            alunoRef.updateData(["sala": ""]) { error in
                if let error = error {
                    print("Erro ao desvincular aluno: \(error.localizedDescription)")
                } else {
                    print("Aluno desvinculado da sala com sucesso.")
                }
            }
            completionHandler(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    //MARK: - Data Manipulation
    
    func carregarAlunos() {
        guard let sala = salaSelecionada else { return }
        
        db.collection("alunos")
            .whereField("sala", isEqualTo: sala.id)
            .order(by: "nome")
            .addSnapshotListener { (snapshot, error) in
                if let e = error {
                    print("Error retrieving data form Firestore -> \(e)")
                } else {
                    if let snapshotDocuments = snapshot?.documents {
                        self.alunos.removeAll()
                        for doc in snapshotDocuments {
                            let data = doc.data()
                            if let nome = data["nome"] as? String, let salaId = data["sala"] as? String {
                                let aluno = Aluno(id: doc.documentID, nome: nome, salaId: nil, salaNome: nil)
                                self.alunos.append(aluno)
                            }
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        
    }
    
    //MARK: - Add Button
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "adicionarAlunos", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! AdicionarAlunosTableViewController
        
        if let sala = salaSelecionada {
            destinationVC.salaSelecionada = sala
        }
    }
    
}

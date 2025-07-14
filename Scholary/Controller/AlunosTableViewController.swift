//
//  AlunosTableViewController.swift
//  Scholary
//
//  Created by Andre Vasques on 11/07/25.
//

import UIKit

class AlunosTableViewController: UITableViewController {
    
    let alunoService = AlunoService()
    var alunos: [Aluno] = []
    
    var alunoForEdit: Aluno?

    override func viewDidLoad() {
        super.viewDidLoad()

        alunoService.carregarTodosOsAlunos { [weak self] alunos in
            DispatchQueue.main.async {
                self?.alunos = alunos
                self?.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alunos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlunosCell", for: indexPath)
        
        let aluno = alunos[indexPath.row]
        
        if let salaNome = aluno.salaNome, !salaNome.isEmpty {
            cell.textLabel?.text = "\(aluno.nome) | \(salaNome)"
        } else {
            cell.textLabel?.text = aluno.nome
        }
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let editarAction = UIContextualAction(style: .normal, title: "Editar") { _, _, completionHandler in
            self.alunoForEdit = self.alunos[indexPath.row]
            self.performSegue(withIdentifier: "goToEditarAlunoFromAlunos", sender: self)
        }
        
        let removerAction = UIContextualAction(style: .destructive, title: "Desvincular") { _, _, completionHandler in
            let alunoASerDesvinculado = self.alunos[indexPath.row]
            self.alunoService.desvincularAlunoSala(alunoASerDesvinculado: alunoASerDesvinculado) { aluno in
                tableView.reloadData()
                self.validationAlert(title: "\(aluno.nome)", message: "Aluno desvinculado da sala com sucesso.")
            }
            completionHandler(true)
        }
        
        let aluno = alunos[indexPath.row]
        
        if let salaNome = aluno.salaNome, !salaNome.isEmpty {
            return UISwipeActionsConfiguration(actions: [removerAction, editarAction])
        } else {
            return UISwipeActionsConfiguration(actions: [editarAction])
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEditarAlunoFromAlunos" {
            if let nav = segue.destination as? UINavigationController,
               let destination = nav.viewControllers.first as? EditarAlunoViewController {
                if let aluno = alunoForEdit {
                    destination.aluno = aluno
                }
            }
        }
    }

}

//MARK: - UISearchBarDelegate

extension AlunosTableViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            alunoService.carregarTodosOsAlunos { [weak self] alunos in
                DispatchQueue.main.async {
                    self?.alunos = alunos
                    self?.tableView.reloadData()
                    searchBar.resignFirstResponder()
                }
            }
        } else{
            alunos = alunos.filter { $0.nome.localizedCaseInsensitiveContains(searchText) }
            
            tableView.reloadData()
        }
    }
}


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

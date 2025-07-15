//
//  AdicionarAlunosTableViewController.swift
//  Scholary
//
//  Created by Andre Vasques on 07/07/25.
//

import UIKit
import FirebaseFirestore

class VincularAlunosTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    let alunoService = AlunoService()
    var alunos: [Aluno] = []
    var alunosSelecionados: Set<Int> = []
    var salaSelecionada: Sala?
    
    @IBOutlet weak var novoAlunoButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!

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
    
    //MARK: - Done Button Pressed

    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        guard let salaSelecionada = salaSelecionada else {
            validationAlert(title: "Erro", message: "Nenhuma sala selecionada.")
            return
        }
        alunoService.vincularAlunosSala(salaSelecionada: salaSelecionada, alunosParaVincular: alunosSelecionados, alunosArray: alunos) { [weak self] alunos in
            self?.navigationController?.popViewController(animated: true)
            self?.validationAlert(title: "Alunos vinculados", message: "\(alunos.count) foram vinculados à \(salaSelecionada.nome)")
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

extension VincularAlunosTableViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            alunoService.carregarTodosOsAlunos { [weak self] alunos in
                self?.alunos = alunos
            }
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        } else{
            alunos = alunos.filter { $0.nome.localizedCaseInsensitiveContains(searchText) }
            
            tableView.reloadData()
        }
    }
}

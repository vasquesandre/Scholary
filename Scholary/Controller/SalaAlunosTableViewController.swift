//
//  AlunosTableViewController.swift
//  Scholary
//
//  Created by Andre Vasques on 07/07/25.
//

import UIKit

class SalaAlunosTableViewController: UITableViewController {
    
    let alunoService = AlunoService()
    var alunos: [Aluno] = []
    
    var salaSelecionada: Sala?
    
    var indexPathParaEditar: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        alunoService.carregarAlunosSala(salaSelecionada: salaSelecionada) { [weak self] alunos in
            DispatchQueue.main.async {
                self?.alunos = alunos
                self?.tableView.reloadData()
            }
        }
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
        
        let editarAction = UIContextualAction(style: .normal, title: "Editar") { _, _, completionHandler in
            self.indexPathParaEditar = indexPath
            self.performSegue(withIdentifier: "goToEditarAlunoFromSalaAlunos", sender: self)
        }
        
        let removerAction = UIContextualAction(style: .destructive, title: "Remover") { _, _, completionHandler in
            let alunoASerDesvinculado = self.alunos[indexPath.row]
            self.alunoService.desvincularAlunoSala(alunoASerDesvinculado: alunoASerDesvinculado) { aluno in
                self.alunos.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                self.validationAlert(title: "\(aluno.nome)", message: "Aluno removido da sala com sucesso.")
            }
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [removerAction, editarAction])
    }
    
    //MARK: - Add Button
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "adicionarAlunos", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "adicionarAlunos" {
            if let destination = segue.destination as? VincularAlunosTableViewController, let sala = salaSelecionada {
                destination.salaSelecionada = sala
            }
        } else if segue.identifier == "goToEditarAlunoFromSalaAlunos" {
            if let destination = segue.destination as? EditarAlunoViewController {
                let indexPath = indexPathParaEditar ?? tableView.indexPathForSelectedRow
                if let indexPath = indexPath {
                    destination.aluno = alunos[indexPath.row]
                    indexPathParaEditar = nil
                }
            }
        }
    }
    
}
